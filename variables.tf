variable "project" {
  default = "roboshop"
}

variable "environment" {
  default = "dev"
}

variable "rule_priority" {
  type = string
}

variable "component" {
  type = string
}

variable "app_version" {
  type = string
  default = "v3"
}

variable "domain_name" {
  type = string
}