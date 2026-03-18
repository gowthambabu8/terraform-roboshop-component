locals {
  common_tags = {
    Name = "${var.project}-${var.environment}"
    Project = var.project
    Environment = var.environment
    Terraform = true
  }
}