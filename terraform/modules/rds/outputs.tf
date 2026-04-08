# terraform/modules/rds/outputs.tf
output "db_endpoint" {
  description = "RDS connection endpoint"
  value       = aws_db_instance.main.endpoint
}

output "db_name" {
  value = aws_db_instance.main.db_name
}

output "database_url" {
  description = "Full PostgreSQL connection string"
  value       = "postgresql://${var.db_username}:${var.db_password}@${aws_db_instance.main.endpoint}/${var.db_name}"
  sensitive   = true
}
