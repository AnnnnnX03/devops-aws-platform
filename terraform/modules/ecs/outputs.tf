# terraform/modules/ecs/outputs.tf

output "alb_dns_name" {
  description = "DNS name of the load balancer"
  value       = aws_lb.main.dns_name
}

output "backend_ecr_url" {
  description = "ECR repository URL for backend image"
  value       = aws_ecr_repository.backend.repository_url
}

output "ai_service_ecr_url" {
  description = "ECR repository URL for AI service image"
  value       = aws_ecr_repository.ai_service.repository_url
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.main.name
}
