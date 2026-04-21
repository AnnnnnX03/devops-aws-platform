# terraform/modules/rds/main.tf
# ─────────────────────────────────────────────────────────────
# RDS MODULE — PostgreSQL in private subnet
# ─────────────────────────────────────────────────────────────

# Subnet group tells RDS which subnets it can use
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = var.private_subnet_ids          # Database ONLY in private subnets

  tags = {
    Name        = "${var.project_name}-db-subnet-group"
    Environment = var.environment
  }
}

resource "aws_db_instance" "main" {
  identifier = "${var.project_name}-db"

  # Engine
  engine         = "postgres"
  engine_version = "15"
  instance_class = "db.t3.micro"              # Free tier eligible

  # Storage
  allocated_storage     = 20
  max_allocated_storage = 100                  # Auto-scaling storage up to 100GB
  storage_encrypted     = true                 # Encrypt data at rest

  # Credentials
  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  # Network
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.rds_security_group_id]
  publicly_accessible    = false               # NO public access — private only

  # Backup
  backup_retention_period = 7                  # Keep backups for 7 days
  backup_window           = "03:00-04:00"      # Backup at 3am UTC

  # Maintenance
  maintenance_window         = "Mon:04:00-Mon:05:00"
  auto_minor_version_upgrade = true

  # Don't delete DB when running terraform destroy (safety net)
  skip_final_snapshot = true                   # Set to false in production!

  tags = {
    Name        = "${var.project_name}-db"
    Environment = var.environment
  }
}
