# terraform/modules/ecs/variables.tf

variable "project_name" { type = string }
variable "environment" { type = string }
variable "aws_region" { type = string }
variable "vpc_id" { type = string }
variable "public_subnet_ids" { type = list(string) }
variable "private_subnet_ids" { type = list(string) }
variable "alb_security_group_id" { type = string }
variable "ecs_security_group_id" { type = string }
variable "database_url" {
  type      = string
  sensitive = true                             # Terraform won't print this in logs
}
