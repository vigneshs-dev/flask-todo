terraform {
  backend "s3" {
    bucket         = "flask-todo-terraform-backend-state-bucket"
    key            = "terraform/flask-todo/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}