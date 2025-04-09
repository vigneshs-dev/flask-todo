output "rds_sg_id" {
  description = "ID of the RDS security group"
  value       = aws_security_group.rds_sg.id
}

output "ecs_task_sg_id" {
  description = "ID of the ECS task security group"
  value       = aws_security_group.ecs_task_sg.id
}

output "alb_sg_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.alb_sg.id
}