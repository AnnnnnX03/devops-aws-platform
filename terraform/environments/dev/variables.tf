# terraform/environments/dev/variables.tf

variable "project_name" {
  description = "Project name used for naming all resources"
  type        = string
  default     = "devops-platform"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "ap-southeast-2"              # Sydney — closest to Adelaide
}

variable "db_password" {
  description = "Database password — set via environment variable TF_VAR_db_password"
  type        = string
  sensitive   = true
}
