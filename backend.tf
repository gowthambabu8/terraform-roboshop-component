resource "aws_instance" "main" {
  ami           = local.ami_id
  instance_type = "t3.micro"
  subnet_id = local.subnet_id
  vpc_security_group_ids = [local.sg_id]
  tags = merge(local.common_tags,
    {
      Name = "${var.project}-${var.environment}-${var.component}"
    }
    )
}

resource "terraform_data" "bootstrap_instance" {
  triggers_replace = [
    aws_instance.main.id
  ]

  connection {
    type = "ssh"
    user = "ec2-user"
    password = "DevOps321"
    host = aws_instance.main.private_ip
  }

  provisioner "file" {
    source = "${path.module}/bootstrap.sh"
    destination = "/tmp/bootstrap.sh"
  }

  provisioner "remote-exec" {
    inline = [ 
      "chmod +x /tmp/bootstrap.sh",
      "sudo sh /tmp/bootstrap.sh ${var.component} ${var.environment} ${var.app_version}"
     ]
  }
}

resource "aws_ec2_instance_state" "main" {
  instance_id = aws_instance.main.id
  state = "stopped"
  depends_on = [ terraform_data.bootstrap_instance ]
}

resource "aws_ami_from_instance" "main" {
  name = "${var.project}-${var.environment}-${var.component}-${var.app_version}-${aws_instance.main.id}"
  source_instance_id = aws_instance.main.id
  depends_on = [ aws_ec2_instance_state.main ]
  tags = merge(local.common_tags,
    {
      Name = "${var.project}-${var.environment}-${var.component}"
    }
    )
}

resource "aws_lb_target_group" "main" {
  name = "${var.project}-${var.environment}-${var.component}"
  port = local.port_number
  protocol = "HTTP"
  vpc_id = local.vpc_id
  deregistration_delay = 60

  health_check {
    enabled = true
    healthy_threshold = 2
    interval = 30
    matcher = "200-299"
    path = "${local.health_check_path}"
    port = local.port_number
    protocol = "HTTP"
    timeout = 20
    unhealthy_threshold = 2
  }
}

resource "aws_launch_template" "main" {
  name = "${var.project}-${var.environment}-${var.component}"
  image_id = aws_ami_from_instance.main.id

  instance_initiated_shutdown_behavior = "terminate"
  instance_type = "t3.micro"
  vpc_security_group_ids = [local.sg_id]
  update_default_version = true

  tag_specifications {
    resource_type = "instance"

    tags = merge(local.common_tags,
    {
      Name = "${var.project}-${var.environment}-${var.component}-instance"
    }
    )
  }

  tag_specifications {
    resource_type = "volume"

    tags = merge(local.common_tags,
    {
      Name = "${var.project}-${var.environment}-${var.component}-volume"
    }
    )
  }

  tags = merge(local.common_tags,
    {
      Name = "${var.project}-${var.environment}-${var.component}"
    }
    )
}

resource "aws_autoscaling_group" "main" {
  name = "${var.project}-${var.environment}-${var.component}"
  max_size = 10
  min_size = 1
  desired_capacity = 1
  health_check_grace_period = 120
  health_check_type = "ELB"
  force_delete = false

  launch_template {
    id = aws_launch_template.main.id
    version = "$Latest"
  }

  vpc_zone_identifier = [ local.subnet_id ]
  target_group_arns = [ aws_lb_target_group.main.arn ]

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
    triggers = [ "launch_template" ]
  }

  # instances should be launched in given time else timeout from ASG.
  timeouts {
    delete = "15m"
  }

  dynamic "tag" {
    for_each = merge(
      {
        Name = "${var.project}-${var.environment}-${var.component}"
      },
      local.common_tags
    )
    content {
      key = tag.key
      value = tag.value
      propagate_at_launch = true
    }
  }
}

resource "aws_autoscaling_policy" "main" {
  autoscaling_group_name = aws_autoscaling_group.main.name
  name = "${var.project}-${var.environment}-${var.component}"
  policy_type = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
  
  target_value = 70.0
  }
}

resource "aws_alb_listener_rule" "main" {
    listener_arn = local.alb_listener
    priority = local.rule_priority

    condition {
      host_header {
        values = [ local.listener_header ]
      }
    }

    action {
      type = "forward"
      target_group_arn = aws_lb_target_group.main.arn
    }
}

resource "terraform_data" "main_delete" {
  triggers_replace = [
    aws_instance.main.id
  ]
  depends_on = [ aws_autoscaling_policy.main ]
  provisioner "local-exec" {
    command = "aws ec2 terminate-instances --instance-ids ${aws_instance.main.id} "
  }
}