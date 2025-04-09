output "rds_endpoint" {
  description = "The endpoint of the database"
  value       = aws_db_instance.todo_rds.endpoint
}

output "rds_port" {
  description = "The port of the database"
  value       = aws_db_instance.todo_rds.port
}

output "db_username" {
  description = "Database username"
  value       = aws_db_instance.todo_rds.username
}

output "db_password" {
  description = "Database password"
  value       = aws_db_instance.todo_rds.password
  sensitive   = true
}

output "db_name" {
  description = "Database name"
  value       = aws_db_instance.todo_rds.db_name
}