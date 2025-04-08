provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "main_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name = "Main VPC"
  }
}

# We need at least two subnets in different AZs for RDS
resource "aws_subnet" "main_subnet_1" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  
  tags = {
    Name = "Main Subnet 1"
  }
}

resource "aws_subnet" "main_subnet_2" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
  
  tags = {
    Name = "Main Subnet 2"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main_vpc.id
  
  tags = {
    Name = "Main IGW"
  }
}

resource "aws_route_table" "rtable" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  
  tags = {
    Name = "Main Route Table"
  }
}

resource "aws_route_table_association" "a1" {
  subnet_id      = aws_subnet.main_subnet_1.id
  route_table_id = aws_route_table.rtable.id
}

resource "aws_route_table_association" "a2" {
  subnet_id      = aws_subnet.main_subnet_2.id
  route_table_id = aws_route_table.rtable.id
}

# Get your current public IP address
data "http" "my_ip" {
  url = "https://checkip.amazonaws.com/"
}

resource "aws_security_group" "rds_sg" {
  name        = "allow_mysql"
  description = "Allow MySQL inbound traffic from specific IP"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    # Use your IP instead of opening to the world
    cidr_blocks = ["0.0.0.0/0"]
    # cidr_blocks = ["${chomp(data.http.my_ip.body)}/32"]
    description = "Allow MySQL access from your IP only"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }
  
  tags = {
    Name = "RDS Security Group"
  }
}

resource "aws_db_subnet_group" "db_subnet_group" {
  name        = "main-db-subnet-group"
  description = "DB subnet group for RDS"
  subnet_ids  = [aws_subnet.main_subnet_1.id, aws_subnet.main_subnet_2.id]
  
  tags = {
    Name = "Main DB Subnet Group"
  }
}

resource "aws_db_instance" "todo_rds" {
  identifier             = "flask-todo-db"
  allocated_storage      = 20
  storage_type           = "gp2"
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = "db.t3.micro"
  db_name                = "flask_todo_db"
  username               = "flaskuser"
  password               = "flaskpassword123!" # Use a more secure password in production
  parameter_group_name   = "default.mysql5.7"
  skip_final_snapshot    = true
  publicly_accessible    = true
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
  backup_retention_period = 7
  multi_az               = false # Set to true for production environments
  
  tags = {
    Name = "Flask Todo Database"
  }
}

# Create ECR Repository
resource "aws_ecr_repository" "flask_todo_repo" {
  name                 = "flask-todo-app"
  image_tag_mutability = "MUTABLE"
  
  image_scanning_configuration {
    scan_on_push = true
  }
  
  tags = {
    Name = "Flask Todo App Repository"
  }
}

# ECR Lifecycle policy to keep only 5 images
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

output "rds_endpoint" {
  description = "The endpoint of the database"
  value       = aws_db_instance.todo_rds.endpoint
}

output "rds_port" {
  description = "The port of the database"
  value       = aws_db_instance.todo_rds.port
}

output "ecr_repository_url" {
  description = "The URL of the ECR repository"
  value       = aws_ecr_repository.flask_todo_repo.repository_url
}

output "aws_region" {
  description = "The AWS region"
  value       = "us-east-1"
}

output "db_username" {
  description = "Database username"
  value       = aws_db_instance.todo_rds.username
}

output "db_name" {
  description = "Database name"
  value       = aws_db_instance.todo_rds.db_name
}