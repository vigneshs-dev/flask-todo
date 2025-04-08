provider "aws" {
  region = "us-east-1"
}

# VPC Configuration
resource "aws_vpc" "main_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name = "Main VPC"
  }
}

# Subnets across multiple AZs
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

# Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main_vpc.id
  
  tags = {
    Name = "Main IGW"
  }
}

# Route Table
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

# Route Table Associations
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

# RDS Security Group
resource "aws_security_group" "rds_sg" {
  name        = "allow_mysql"
  description = "Allow MySQL inbound traffic from specific IP and ECS tasks"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    # cidr_blocks = ["${chomp(data.http.my_ip.body)}/32"]
    description = "Allow MySQL access from your IP only"
  }

  # Allow access from ECS tasks
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_task_sg.id]
    description     = "Allow MySQL access from ECS tasks"
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

# DB Subnet Group
resource "aws_db_subnet_group" "db_subnet_group" {
  name        = "main-db-subnet-group"
  description = "DB subnet group for RDS"
  subnet_ids  = [aws_subnet.main_subnet_1.id, aws_subnet.main_subnet_2.id]
  
  tags = {
    Name = "Main DB Subnet Group"
  }
}

# RDS MySQL Instance
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

# ECR Repository
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

# ECS Cluster
resource "aws_ecs_cluster" "app_cluster" {
  name = "flask-todo-cluster"
  
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
  
  tags = {
    Name = "Flask Todo Cluster"
  }
}

# ECS Task Execution Role
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "flask-todo-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

# Attach policies to ECS Task Execution Role
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECS Task Role
resource "aws_iam_role" "ecs_task_role" {
  name = "flask-todo-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

# Create a custom policy for CloudWatch Logs permissions
resource "aws_iam_policy" "ecs_cloudwatch_logs_policy" {
  name        = "ECSCloudWatchLogsPolicy"
  description = "Policy that allows ECS tasks to create and manage CloudWatch log groups"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

# Attach the CloudWatch Logs policy to the ECS task execution role
resource "aws_iam_role_policy_attachment" "ecs_cloudwatch_logs_policy_attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ecs_cloudwatch_logs_policy.arn
}

# Security Group for ECS tasks
resource "aws_security_group" "ecs_task_sg" {
  name        = "ecs-task-sg"
  description = "Security group for ECS Tasks"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    from_port       = 5000
    to_port         = 5000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
    description     = "Allow access from ALB"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }
  
  tags = {
    Name = "ECS Task Security Group"
  }
}

# Security Group for ALB
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP traffic"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }
  
  tags = {
    Name = "ALB Security Group"
  }
}

# Application Load Balancer
resource "aws_lb" "app_lb" {
  name               = "flask-todo-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.main_subnet_1.id, aws_subnet.main_subnet_2.id]
  
  enable_deletion_protection = false
  
  tags = {
    Name = "Flask Todo ALB"
  }
}

# Target Group for ALB
resource "aws_lb_target_group" "app_tg" {
  name        = "flask-todo-tg"
  port        = 5000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main_vpc.id
  target_type = "ip"
  
  health_check {
    enabled             = true
    path                = "/"
    port                = "traffic-port"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }
  
  tags = {
    Name = "Flask Todo Target Group"
  }
}

# Listener for ALB
resource "aws_lb_listener" "app_listener" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 80
  protocol          = "HTTP"
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

# ECS Task Definition
resource "aws_ecs_task_definition" "app_task" {
  family                   = "flask-todo-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  
  container_definitions = jsonencode([
    {
      name      = "flask-todo-container"
      image     = "${aws_ecr_repository.flask_todo_repo.repository_url}:latest"
      essential = true
      
      portMappings = [
        {
          containerPort = 5000
          hostPort      = 5000
          protocol      = "tcp"
        }
      ]
      
      environment = [
        {
          name  = "DATABASE_URI"
          value = "mysql+mysqlconnector://${aws_db_instance.todo_rds.username}:${aws_db_instance.todo_rds.password}@${aws_db_instance.todo_rds.endpoint}/${aws_db_instance.todo_rds.db_name}"
        }
      ]
      
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/flask-todo"
          "awslogs-region"        = "us-east-1"
          "awslogs-stream-prefix" = "ecs"
          "awslogs-create-group"  = "true"
        }
      }
    }
  ])
  
  tags = {
    Name = "Flask Todo Task Definition"
  }
}

# ECS Service
resource "aws_ecs_service" "app_service" {
  name            = "flask-todo-service"
  cluster         = aws_ecs_cluster.app_cluster.id
  task_definition = aws_ecs_task_definition.app_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  
  network_configuration {
    subnets          = [aws_subnet.main_subnet_1.id, aws_subnet.main_subnet_2.id]
    security_groups  = [aws_security_group.ecs_task_sg.id]
    assign_public_ip = true
  }
  
  load_balancer {
    target_group_arn = aws_lb_target_group.app_tg.arn
    container_name   = "flask-todo-container"
    container_port   = 5000
  }
  
  depends_on = [aws_lb_listener.app_listener]
  
  tags = {
    Name = "Flask Todo Service"
  }
}

# Outputs
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

output "alb_dns_name" {
  description = "The DNS name of the Application Load Balancer"
  value       = aws_lb.app_lb.dns_name
}