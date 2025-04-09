output "cluster_id" {
  description = "ID of the ECS cluster"
  value       = aws_ecs_cluster.app_cluster.id
}

output "cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.app_cluster.name
}

output "alb_dns_name" {
  description = "The DNS name of the Application Load Balancer"
  value       = aws_lb.app_lb.dns_name
}

output "task_definition_arn" {
  description = "ARN of the ECS task definition"
  value       = aws_ecs_task_definition.app_task.arn
}

output "service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.app_service.name
}