output "rds_endpoint" {
  description = "The endpoint of the database"
  value       = module.database.rds_endpoint
}

output "rds_port" {
  description = "The port of the database"
  value       = module.database.rds_port
}

output "ecr_repository_url" {
  description = "The URL of the ECR repository"
  value       = module.ecr.repository_url
}

output "aws_region" {
  description = "The AWS region"
  value       = var.aws_region
}

output "db_username" {
  description = "Database username"
  value       = module.database.db_username
}

output "db_name" {
  description = "Database name"
  value       = module.database.db_name
}

output "alb_dns_name" {
  description = "The DNS name of the Application Load Balancer"
  value       = module.ecs.alb_dns_name
}