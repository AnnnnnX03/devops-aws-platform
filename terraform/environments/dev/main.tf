# terraform/environments/dev/main.tf
# ─────────────────────────────────────────────────────────────
# DEV ENVIRONMENT — Entry point that calls all modules
# This is what you run: terraform init && terraform apply
# ─────────────────────────────────────────────────────────────

terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Store Terraform state in S3 (uncomment after creating the bucket)
  # backend "s3" {
  #   bucket = "your-project-terraform-state"
  #   key    = "dev/terraform.tfstate"
  #   region = "ap-southeast-2"
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# ── MODULE 1: VPC ─────────────────────────────────────────────
module "vpc" {
  source = "../../modules/vpc"

  project_name = var.project_name
  environment  = var.environment
}

# ── MODULE 2: RDS ─────────────────────────────────────────────
module "rds" {
  source = "../../modules/rds"

  project_name          = var.project_name
  environment           = var.environment
  private_subnet_ids    = module.vpc.private_subnet_ids
  rds_security_group_id = module.vpc.rds_security_group_id
  db_password           = var.db_password
}

# ── MODULE 3: ECS ─────────────────────────────────────────────
module "ecs" {
  source = "../../modules/ecs"

  project_name          = var.project_name
  environment           = var.environment
  aws_region            = var.aws_region
  vpc_id                = module.vpc.vpc_id
  public_subnet_ids     = module.vpc.public_subnet_ids
  private_subnet_ids    = module.vpc.private_subnet_ids
  alb_security_group_id = module.vpc.alb_security_group_id
  ecs_security_group_id = module.vpc.ecs_security_group_id
  database_url          = module.rds.database_url
}
