# terraform/environments/prod/variables.tf

variable "aws_region" {
  description = "The AWS region to deploy into"
  type        = string
  default     = "eu-central-1"
}

variable "environment" {
  description = "The name of the environment"
  type        = string
  default     = "prod"
}