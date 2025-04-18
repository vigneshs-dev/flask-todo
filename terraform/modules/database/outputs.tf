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

# Remove the db_password output for security
# Instead, use the secret ARN to access the password

output "db_name" {
  description = "Database name"
  value       = aws_db_instance.todo_rds.db_name
}

output "secrets_access_policy_arn" {
  description = "ARN of the policy to access database secrets"
  value       = aws_iam_policy.secrets_access.arn
}