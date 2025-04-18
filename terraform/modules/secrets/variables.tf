variable "environment" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
  default     = "dev"
}

variable "db_name" {
  description = "Name of the database"
  type        = string
}

variable "db_username" {
  description = "Username for the database"
  type        = string
}

variable "db_password" {
  description = "Password for the database (leave empty to generate random password)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "db_endpoint" {
  description = "Endpoint of the database"
  type        = string
  default     = ""
}

variable "db_port" {
  description = "Port of the database"
  type        = string
  default     = "3306"
}