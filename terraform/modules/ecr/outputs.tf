output "repository_url" {
  description = "The URL of the ECR repository"
  value       = aws_ecr_repository.flask_todo_repo.repository_url
}

output "repository_name" {
  description = "The name of the ECR repository"
  value       = aws_ecr_repository.flask_todo_repo.name
}