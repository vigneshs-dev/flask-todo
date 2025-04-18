variable "subnet_ids" {
  description = "List of subnet IDs for DB subnet group"
  type        = list(string)
}

variable "rds_sg_id" {
  description = "ID of the RDS security group"
  type        = string
}

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
  sensitive   = true
}

variable "environment" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
  default     = "dev"
}

variable "secret_arn" {
  description = "ARN of the secret in Secrets Manager"
  type        = string
  default     = ""
}