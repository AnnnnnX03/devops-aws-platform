# terraform/modules/ecs/main.tf
# ─────────────────────────────────────────────────────────────
# ECS MODULE
# Creates: ECR repo, ECS Cluster, Task Definition, Service, ALB
# ─────────────────────────────────────────────────────────────

# ── 1. ECR REPOSITORY ────────────────────────────────────────
# ECR = Elastic Container Registry = AWS's private Docker Hub
# Your Docker images get pushed here before ECS pulls them
resource "aws_ecr_repository" "backend" {
  name                 = "${var.project_name}-backend"
  image_tag_mutability = "MUTABLE"
  force_delete         = true   

  image_scanning_configuration {
    scan_on_push = true                        # Automatically scan for vulnerabilities
  }

  tags = {
    Name        = "${var.project_name}-backend-ecr"
    Environment = var.environment
  }
}

resource "aws_ecr_repository" "ai_service" {
  name                 = "${var.project_name}-ai-service"
  image_tag_mutability = "MUTABLE"
  force_delete         = true   

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "${var.project_name}-ai-service-ecr"
    Environment = var.environment
  }
}

# ── 2. ECS CLUSTER ───────────────────────────────────────────
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"                          # Enables CloudWatch container metrics
  }

  tags = {
    Name        = "${var.project_name}-cluster"
    Environment = var.environment
  }
}

# ── 3. IAM ROLE for ECS Tasks ────────────────────────────────
# ECS needs permission to pull images from ECR and write to CloudWatch
resource "aws_iam_role" "ecs_task_execution" {
  name = "${var.project_name}-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ── 4. CLOUDWATCH LOG GROUP ───────────────────────────────────
resource "aws_cloudwatch_log_group" "backend" {
  name              = "/ecs/${var.project_name}/backend"
  retention_in_days = 7                        # Keep logs for 7 days (cost saving)
}

resource "aws_cloudwatch_log_group" "ai_service" {
  name              = "/ecs/${var.project_name}/ai-service"
  retention_in_days = 7
}

# ── 5. ECS TASK DEFINITION (Backend) ─────────────────────────
# Task Definition = the "recipe" for running your container
# It defines: which image, how much CPU/memory, env vars, ports
resource "aws_ecs_task_definition" "backend" {
  family                   = "${var.project_name}-backend"
  network_mode             = "awsvpc"          # Required for Fargate
  requires_compatibilities = ["FARGATE"]       # Serverless containers — no EC2 to manage
  cpu                      = "256"             # 0.25 vCPU
  memory                   = "512"             # 512 MB RAM
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([{
    name      = "backend"
    image     = "${aws_ecr_repository.backend.repository_url}:latest"
    essential = true

    portMappings = [{
      containerPort = 8000
      protocol      = "tcp"
    }]

    environment = [
      { name = "ENVIRONMENT", value = var.environment },
      { name = "DATABASE_URL", value = var.database_url }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.backend.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "backend"
      }
    }
  }])
}

# ── 6. APPLICATION LOAD BALANCER ─────────────────────────────
resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false                   # Public-facing
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = var.public_subnet_ids   # ALB lives in PUBLIC subnets

  tags = {
    Name        = "${var.project_name}-alb"
    Environment = var.environment
  }
}

resource "aws_lb_target_group" "backend" {
  name        = "${var.project_name}-backend-tg"
  port        = 8000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"                           # Required for Fargate

  health_check {
    path                = "/health"            # FastAPI health check endpoint
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }
}

# ── 7. ECS SERVICE ───────────────────────────────────────────
# Service = keeps N copies of your Task Definition running
# If one dies, it auto-restarts — this is the "zero downtime" part
resource "aws_ecs_service" "backend" {
  name            = "${var.project_name}-backend-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.backend.arn
  desired_count   = 2                          # Always keep 2 containers running
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids  # ECS runs in PRIVATE subnets
    security_groups  = [var.ecs_security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.backend.arn
    container_name   = "backend"
    container_port   = 8000
  }

  # Rolling update = zero downtime deployments
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200
}

# ── 8. AUTO SCALING ──────────────────────────────────────────
resource "aws_appautoscaling_target" "ecs" {
  max_capacity       = 4
  min_capacity       = 2
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.backend.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# Scale up when CPU > 70%
resource "aws_appautoscaling_policy" "cpu" {
  name               = "${var.project_name}-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 70.0
  }
}
