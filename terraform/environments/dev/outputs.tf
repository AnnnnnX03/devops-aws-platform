# terraform/environments/dev/outputs.tf

output "alb_dns_name" {
  description = "Your app's URL — paste this in browser"
  value       = module.ecs.alb_dns_name
}

output "backend_ecr_url" {
  description = "Push your Docker image here"
  value       = module.ecs.backend_ecr_url
}

output "ecs_cluster_name" {
  value = module.ecs.ecs_cluster_name
}
