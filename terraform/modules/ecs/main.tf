# ECS Cluster
resource "aws_ecs_cluster" "app_cluster" {
  name = var.cluster_name
  
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
  
  tags = {
    Name = "Flask Todo Cluster"
  }
}

# Application Load Balancer
resource "aws_lb" "app_lb" {
  name               = "flask-todo-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.subnet_ids
  
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
  vpc_id      = var.vpc_id
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
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  
  container_definitions = jsonencode([
    {
      name      = "flask-todo-container"
      image     = "${var.repository_url}:latest"
      essential = true
      
      portMappings = [
        {
          containerPort = 5000
          hostPort      = 5000
          protocol      = "tcp"
        }
      ]
      
      # Remove the hardcoded DATABASE_URI environment variable
      # Instead, provide the SECRET_NAME environment variable
      environment = [
        {
          name  = "AWS_REGION"
          value = var.aws_region
        },
        {
          name  = "SECRET_NAME"
          value = var.secret_name
        }
      ]
      
      # You can also use the secrets parameter to directly inject values from Secrets Manager
      # This is an alternative approach that doesn't require boto3 in your application
      secrets = [
        {
          name      = "DB_HOST",
          valueFrom = "${var.secret_arn}:host::"
        },
        {
          name      = "DB_PORT", 
          valueFrom = "${var.secret_arn}:port::"
        },
        {
          name      = "DB_NAME",
          valueFrom = "${var.secret_arn}:dbname::"
        },
        {
          name      = "DB_USER",
          valueFrom = "${var.secret_arn}:username::"
        },
        {
          name      = "DB_PASSWORD",
          valueFrom = "${var.secret_arn}:password::"
        }
      ]
      
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/flask-todo"
          "awslogs-region"        = var.aws_region
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
  desired_count   = var.service_desired_count
  launch_type     = "FARGATE"
  
  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [var.ecs_task_sg_id]
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