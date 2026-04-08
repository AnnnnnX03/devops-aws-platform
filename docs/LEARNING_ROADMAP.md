# 📅 学习路线图 / Learning Roadmap

这个文件是你的每周任务清单。每完成一步，在checkbox打勾。

---

## Week 1 — 环境 + 网络基础 / Environment & Networking

### 理论课 (30 min/day)
- [ ] 课1：Cloud 的本质 ✅ (已完成)
- [ ] 课2：网络底层逻辑 — IP, CIDR, DNS, Load Balancer ✅ (已完成)
- [ ] 课3：Linux 命令行基础
- [ ] 课4：什么是 Docker？容器 vs 虚拟机

### 项目任务
- [ ] 安装所有工具 (aws cli, terraform, docker) ✅
- [ ] 创建 GitHub repo ✅
- [ ] 把这个项目 push 到你的 GitHub
- [ ] 本地运行：`docker-compose up --build`
- [ ] 浏览器打开 `http://localhost:8000/health` 看到 {"status":"healthy"}
- [ ] 浏览器打开 `http://localhost:8000/docs` 看 FastAPI 自动生成的 API 文档
- [ ] 浏览器打开 `http://localhost:3000` 看 Grafana (admin/admin)

---

## Week 2 — Terraform + VPC 部署

### 理论课
- [ ] 课5：什么是 Infrastructure as Code？为什么用 Terraform？
- [ ] 课6：Terraform 工作原理 — init, plan, apply, destroy
- [ ] 课7：AWS IAM — 权限和角色是怎么工作的

### 项目任务
- [ ] 阅读并理解 `terraform/modules/vpc/main.tf` 的每一行注释
- [ ] 运行 `terraform init` 在 dev 环境
- [ ] 运行 `terraform plan` — 读懂输出
- [ ] 运行 `terraform apply` — 创建 VPC
- [ ] 去 AWS Console 确认 VPC, Subnets, Security Groups 都创建了
- [ ] 能向别人解释：为什么 ECS 在 private subnet 但 ALB 在 public subnet？

---

## Week 3 — Docker + ECR + ECS 部署

### 理论课
- [ ] 课8：Docker 镜像 vs 容器 — 底层原理
- [ ] 课9：ECS vs EC2 vs Lambda — 什么时候用什么？
- [ ] 课10：为什么用 multi-stage Docker build？

### 项目任务
- [ ] 本地 build Docker 镜像：`docker build -f docker/Dockerfile.backend .`
- [ ] 创建 ECR 仓库（通过 Terraform）
- [ ] 把镜像 push 到 ECR
- [ ] 部署 ECS 服务
- [ ] 通过 ALB DNS 访问你的 API

---

## Week 4 — GitHub Actions CI/CD

### 理论课
- [ ] 课11：CI/CD 底层逻辑 — 为什么公司需要流水线？
- [ ] 课12：GitHub Actions 工作原理 — jobs, steps, secrets
- [ ] 课13：Rolling deployment vs Blue/Green — 零停机的实现方式

### 项目任务
- [ ] 在 GitHub 配置 secrets (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)
- [ ] 推送一个代码改动到 main 分支
- [ ] 在 GitHub Actions 看 pipeline 自动运行
- [ ] 确认新代码自动部署到 ECS
- [ ] 创建一个 PR，看 pr-check.yml 自动运行测试

---

## Week 5 — 监控 + 4 Golden Signals

### 理论课
- [ ] 课14：什么是可观测性（Observability）？
- [ ] 课15：4 Golden Signals 详解
- [ ] 课16：Logs vs Metrics vs Traces 的区别

### 项目任务
- [ ] 部署 CloudWatch alarms
- [ ] 在 CloudWatch 看你的 ECS 容器日志
- [ ] 配置 Grafana 连接 CloudWatch 数据源
- [ ] 创建 dashboard 展示 4 Golden Signals

---

## Week 6 — AI 服务部署（你的差异化优势）

### 理论课
- [ ] 课17：什么是 API？REST API 底层逻辑
- [ ] 课18：AWS Bedrock vs OpenAI API — 企业怎么选？

### 项目任务
- [ ] 本地测试 AI service：`curl -X POST http://localhost:8001/chat -d '{"message":"hello"}'`
- [ ] 把 AI service push 到 ECR
- [ ] 在 ECS 部署 AI service 作为第二个服务
- [ ] 前端页面连接 AI service

---

## Week 7 — 项目收尾 + 简历准备

### 项目任务
- [ ] 写好 README.md（架构图，部署步骤，技术栈）
- [ ] 截图：AWS Console 里的 VPC, ECS, RDS, CloudWatch
- [ ] 录一个 5 分钟 demo 视频（面试用）
- [ ] 把项目链接加到 LinkedIn 和简历

### 面试准备
- [ ] 能用英文解释项目架构（用你的 README 练习）
- [ ] 准备 5 个 STAR 格式的面试答案
- [ ] 模拟面试：我来问你，你来答

---

## 🎯 完成后你能说的话（面试素材）

> *"I designed and deployed a production-grade 3-tier architecture on AWS using Terraform for infrastructure as code. The system includes ECS Fargate for containerised workloads, RDS PostgreSQL in private subnets, CloudFront for CDN, and GitHub Actions for zero-downtime CI/CD deployments. I also integrated an AI service layer using FastAPI, which is deployed as a separate ECS service. The entire system is monitored using CloudWatch dashboards based on the 4 Golden Signals framework."*

这句话包含了面试官想听到的所有关键词。
