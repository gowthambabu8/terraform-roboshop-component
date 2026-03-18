variable "project" {
  default = "roboshop"
}

variable "environment" {
  default = "dev"
}

variable "subnet_id" {
  type = string
}

variable "sg_id" {
  type = string
}

variable "ami_id" {
  type = string
}

variable "component" {
  type = string
}

variable "app_version" {
  type = string
  default = "v3"
}

variable "port_number" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "health_check_path" {
  type = string
}

variable "backend_alb_arn" {
  type = string
}

variable "domain_name" {
  type = string
  default = "happielearning.com"
}