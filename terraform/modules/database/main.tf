# DB Subnet Group
resource "aws_db_subnet_group" "db_subnet_group" {
  name        = "main-db-subnet-group"
  description = "DB subnet group for RDS"
  subnet_ids  = var.subnet_ids
  
  tags = {
    Name = "Main DB Subnet Group"
  }
}

# RDS MySQL Instance
resource "aws_db_instance" "todo_rds" {
  identifier             = "flask-todo-db"
  allocated_storage      = var.db_allocated_storage
  storage_type           = "gp2"
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = var.db_instance_class
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  parameter_group_name   = "default.mysql5.7"
  skip_final_snapshot    = true
  publicly_accessible    = true
  vpc_security_group_ids = [var.rds_sg_id]
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
  backup_retention_period = 7
  multi_az               = false # Set to true for production environments
  
  tags = {
    Name = "Flask Todo Database"
  }
}