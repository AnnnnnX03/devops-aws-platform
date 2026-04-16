# 🚀 DevOps AWS Platform

A production-grade 3-tier architecture on AWS with CI/CD, monitoring, and an AI API layer.

## 🏗️ Architecture Overview

```
Internet
    │
    ▼
CloudFront (CDN + HTTPS)
    │
    ├──► S3 (Frontend - Static React App)
    │
    └──► ALB (Application Load Balancer)
              │
              ▼
         ECS Fargate (Backend API - Python FastAPI)
              │
              ├──► RDS PostgreSQL (Private Subnet)
              │
              └──► AI Service (Python LLM API on ECS)

Monitoring: CloudWatch + Grafana (4 Golden Signals)
IaC:        Terraform
CI/CD:      GitHub Actions
```

## 📁 Project Structure

```
devops-aws-platform/
├── terraform/
│   ├── modules/
│   │   ├── vpc/          ← Network foundation
│   │   ├── ecs/          ← Container infrastructure
│   │   ├── rds/          ← Database
│   │   └── cloudfront/   ← CDN + Frontend
│   └── environments/
│       └── dev/          ← Dev environment entry point
├── app/
│   ├── backend/          ← Python FastAPI app
│   └── frontend/         ← Simple HTML/JS frontend
├── docker/               ← Dockerfiles
├── .github/workflows/    ← CI/CD pipelines
├── monitoring/           ← Grafana dashboards
└── docs/                 ← Architecture diagrams
```

## 🛠️ Tech Stack

| Layer | Technology |
|-------|-----------|
| Cloud Provider | AWS |
| IaC | Terraform |
| Container Orchestration | ECS Fargate |
| CI/CD | GitHub Actions |
| Backend | Python FastAPI |
| Database | RDS PostgreSQL |
| CDN | CloudFront + S3 |
| Monitoring | CloudWatch + Grafana |
| AI Layer | Python + OpenAI API |

## 🚀 Getting Started

### Prerequisites
- AWS Account with CLI configured
- Terraform >= 1.5
- Docker Desktop
- GitHub Account

### Step 1: Clone and configure
```bash
git clone https://github.com/YOUR_USERNAME/devops-aws-platform.git
cd devops-aws-platform
```

### Step 2: Deploy infrastructure
```bash
cd terraform/environments/dev
terraform init
terraform plan
terraform apply
```

### Step 3: Run locally with Docker
```bash
docker-compose up --build
```

## 📚 Learning Objectives

By completing this project, you will have hands-on experience with:
- ✅ VPC design with public/private subnets
- ✅ ECS Fargate container deployment
- ✅ RDS setup with secure private networking
- ✅ CloudFront + S3 static hosting
- ✅ GitHub Actions CI/CD pipelines
- ✅ Terraform Infrastructure as Code
- ✅ CloudWatch monitoring (4 Golden Signals)
- ✅ Docker multi-stage builds
- ✅ AI API deployment on AWS
# CI/CD Test
