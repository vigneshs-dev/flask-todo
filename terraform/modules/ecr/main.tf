# ECR Repository
resource "aws_ecr_repository" "flask_todo_repo" {
  name                 = var.repository_name
  image_tag_mutability = "MUTABLE"
  
  image_scanning_configuration {
    scan_on_push = true
  }
  
  tags = {
    Name = "Flask Todo App Repository"
  }
}

# ECR Lifecycle policy
resource "aws_ecr_lifecycle_policy" "flask_todo_policy" {
  repository = aws_ecr_repository.flask_todo_repo.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 5 images"
        selection = {
          tagStatus     = "any"
          countType     = "imageCountMoreThan"
          countNumber   = 5
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}