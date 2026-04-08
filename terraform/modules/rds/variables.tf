# terraform/modules/rds/variables.tf
variable "project_name" { type = string }
variable "environment" { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "rds_security_group_id" { type = string }
variable "db_name" { type = string; default = "appdb" }
variable "db_username" { type = string; default = "appuser" }
variable "db_password" { type = string; sensitive = true }
