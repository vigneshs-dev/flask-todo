variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

# VPC Variables
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr_1" {
  description = "CIDR block for subnet 1"
  type        = string
  default     = "10.0.1.0/24"
}

variable "subnet_cidr_2" {
  description = "CIDR block for subnet 2"
  type        = string
  default     = "10.0.2.0/24"
}

variable "availability_zone_1" {
  description = "Availability zone for subnet 1"
  type        = string
  default     = "us-east-1a"
}

variable "availability_zone_2" {
  description = "Availability zone for subnet 2"
  type        = string
  default     = "us-east-1b"
}

# Database Variables
variable "db_allocated_storage" {
  description = "Allocated storage for the RDS instance"
  type        = number
  default     = 20
}

variable "db_instance_class" {
  description = "Instance class for the RDS instance"
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "Name of the database"
  type        = string
  default     = "flask_todo_db"
}

variable "db_username" {
  description = "Username for the database"
  type        = string
  default     = "flaskuser"
}

variable "db_password" {
  description = "Password for the database"
  type        = string
  default     = "flaskpassword123!" # Should use a more secure method in production
}

# ECR Variables
variable "repository_name" {
  description = "Name of the ECR repository"
  type        = string
  default     = "flask-todo-app"
}

# ECS Variables
variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
  default     = "flask-todo-cluster"
}

variable "task_cpu" {
  description = "CPU units for the ECS task"
  type        = number
  default     = 256
}

variable "task_memory" {
  description = "Memory for the ECS task"
  type        = number
  default     = 512
}

variable "service_desired_count" {
  description = "Desired count of ECS tasks"
  type        = number
  default     = 1
}

variable "environment" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
  default     = "dev"
}