output "secret_arn" {
  description = "ARN of the database secrets manager secret"
  value       = aws_secretsmanager_secret.db_secret.arn
}

output "secret_name" {
  description = "Name of the database secrets manager secret"
  value       = aws_secretsmanager_secret.db_secret.name
}

output "db_password" {
  description = "Generated database password (if random password was used)"
  value       = var.db_password == "" ? random_password.db_password[0].result : var.db_password
  sensitive   = true
}