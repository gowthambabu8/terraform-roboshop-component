locals {
  common_tags = {
    Name = "${var.project}-${var.environment}"
    Project = var.project
    Environment = var.environment
    Terraform = true
  }

  ami_id = data.aws_ami.ubuntu.id
  vpc_id = data.aws_ssm_parameter.vpc_id.value
  subnet_id = split(",",data.aws_ssm_parameter.private_subnet_id.value)[0]
  sg_id = data.aws_ssm_parameter.sg_id.value 
  port_number = var.component == "frontend" ? "80" : "8080"
  health_check_path = var.component == "frontend" ? "/" : "/health"
  backend_alb_arn = data.aws_ssm_parameter.backend_alb_arn.value
  frontend_alb_arn = data.aws_ssm_parameter.frontend_alb_arn.value
  alb_listener = var.component == "frontend" ? local.frontend_alb_arn : local.backend_alb_arn
  listener_header = var.component == "frontend" ? "${var.component}-${var.environment}.${var.domain_name}" : "${var.component}.backend-alb-${var.environment}.${var.domain_name}"
  domain_name = var.domain_name
}