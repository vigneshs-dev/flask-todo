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
  
  tags = {
    Name = "ECS Task Execution Role"
  }
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
  
  tags = {
    Name = "ECS Task Role"
  }
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

# Attach the database secrets access policy to the task execution role
# This permits ECS task execution role to access Secrets Manager for secrets during container start
resource "aws_iam_role_policy_attachment" "ecs_task_secrets_access" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = var.secrets_access_policy_arn  # Use the policy from the database module
}

# Attach the database secrets access policy to the task role as well
# This allows the application code to access Secrets Manager directly if needed
resource "aws_iam_role_policy_attachment" "task_role_secrets_access" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = var.secrets_access_policy_arn  # Use the policy from the database module
}