# terraform/modules/vpc/main.tf
# ─────────────────────────────────────────────────────────────
# VPC MODULE
# Creates: VPC, 2 Public Subnets, 2 Private Subnets,
#          Internet Gateway, NAT Gateway, Route Tables
# ─────────────────────────────────────────────────────────────

# ── 1. VPC ───────────────────────────────────────────────────
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr          # e.g. "10.0.0.0/16"
  enable_dns_support   = true                  # Allows DNS resolution inside VPC
  enable_dns_hostnames = true                  # Gives EC2/ECS instances DNS names

  tags = {
    Name        = "${var.project_name}-vpc"
    Environment = var.environment
  }
}

# ── 2. PUBLIC SUBNETS (Load Balancer lives here) ──────────────
resource "aws_subnet" "public" {
  count             = 2                        # 2 subnets = 2 Availability Zones = High Availability
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  # Instances launched here get a public IP automatically
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-public-subnet-${count.index + 1}"
    Environment = var.environment
    Type        = "Public"
  }
}

# ── 3. PRIVATE SUBNETS (ECS + RDS live here) ─────────────────
resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  # NO public IP — this is the security design
  map_public_ip_on_launch = false

  tags = {
    Name        = "${var.project_name}-private-subnet-${count.index + 1}"
    Environment = var.environment
    Type        = "Private"
  }
}

# ── 4. INTERNET GATEWAY (IGW) ─────────────────────────────────
# Think of this as the "front door" of your VPC to the internet
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.project_name}-igw"
    Environment = var.environment
  }
}

# ── 5. ELASTIC IP for NAT Gateway ────────────────────────────
# NAT Gateway needs a static public IP address
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name        = "${var.project_name}-nat-eip"
    Environment = var.environment
  }
}

# ── 6. NAT GATEWAY ───────────────────────────────────────────
# Allows private subnet resources to reach the internet (e.g. pull Docker images)
# But internet CANNOT reach private resources — one-way door
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id     # NAT lives in PUBLIC subnet

  tags = {
    Name        = "${var.project_name}-nat"
    Environment = var.environment
  }

  depends_on = [aws_internet_gateway.main]
}

# ── 7. ROUTE TABLES ──────────────────────────────────────────

# Public route table: all traffic goes through Internet Gateway
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"                  # All traffic
    gateway_id = aws_internet_gateway.main.id  # Goes through IGW
  }

  tags = {
    Name        = "${var.project_name}-public-rt"
    Environment = var.environment
  }
}

# Private route table: outbound traffic goes through NAT Gateway
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id   # Goes through NAT (not IGW)
  }

  tags = {
    Name        = "${var.project_name}-private-rt"
    Environment = var.environment
  }
}

# Associate public subnets with public route table
resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Associate private subnets with private route table
resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# ── 8. SECURITY GROUPS ───────────────────────────────────────

# ALB Security Group: accepts HTTP/HTTPS from anywhere
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]               # Internet can reach ALB on port 80
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]               # Internet can reach ALB on port 443
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"                         # All outbound allowed
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-alb-sg"
    Environment = var.environment
  }
}

# ECS Security Group: only accepts traffic FROM the ALB
resource "aws_security_group" "ecs" {
  name        = "${var.project_name}-ecs-sg"
  description = "Security group for ECS tasks"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 8000                     # FastAPI port
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]  # ONLY from ALB — not from internet
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-ecs-sg"
    Environment = var.environment
  }
}

# RDS Security Group: only accepts traffic FROM ECS
resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg"
  description = "Security group for RDS database"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 5432                     # PostgreSQL port
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id]  # ONLY from ECS
  }

  tags = {
    Name        = "${var.project_name}-rds-sg"
    Environment = var.environment
  }
}
