# Create a random password for the database if not provided
resource "random_password" "db_password" {
  count            = var.db_password == "" ? 1 : 0
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# AWS Secrets Manager Secret
resource "aws_secretsmanager_secret" "db_secret" {
  name        = "${var.environment}-${var.db_name}-credentials"
  description = "Database credentials for ${var.db_name}"
  
  tags = {
    Environment = var.environment
    Application = "Todo Flask App"
  }
}

# # Secret version with credentials
# resource "aws_secretsmanager_secret_version" "db_secret_version" {
#   secret_id = aws_secretsmanager_secret.db_secret.id
  
#   secret_string = jsonencode({
#     username = var.db_username
#     password = var.db_password == "" ? random_password.db_password[0].result : var.db_password
#     engine   = "mysql"
#     host     = var.db_endpoint
#     port     = var.db_port
#     dbname   = var.db_name
#   })
# }