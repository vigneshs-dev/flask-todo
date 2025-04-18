provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source = "./modules/vpc"
  
  vpc_cidr           = var.vpc_cidr
  subnet_cidr_1      = var.subnet_cidr_1
  subnet_cidr_2      = var.subnet_cidr_2
  availability_zone_1 = var.availability_zone_1
  availability_zone_2 = var.availability_zone_2
}

module "security" {
  source = "./modules/security"
  
  vpc_id = module.vpc.vpc_id
}

# First generate passwords and secrets
module "secrets" {
  source = "./modules/secrets"
  
  environment = var.environment
  db_name     = var.db_name
  db_username = var.db_username
  db_password = var.db_password != "" ? var.db_password : ""
  
  # Remove these references to database output
  # db_endpoint = module.database.rds_endpoint
  # db_port     = module.database.rds_port
}

# Then configure database with the generated secrets
module "database" {
  source = "./modules/database"
  
  subnet_ids          = module.vpc.subnet_ids
  rds_sg_id           = module.security.rds_sg_id
  db_allocated_storage = var.db_allocated_storage
  db_instance_class   = var.db_instance_class
  db_name             = var.db_name
  db_username         = var.db_username
  db_password         = module.secrets.db_password
  environment         = var.environment
  secret_arn          = module.secrets.secret_arn
}

resource "aws_secretsmanager_secret_version" "db_connection_update" {
  secret_id     = module.secrets.secret_arn

  secret_string = jsonencode({
    username = var.db_username
    password = module.secrets.db_password
    engine   = "mysql"
    host     = split(":", module.database.rds_endpoint)[0] # <-- removes port
    port     = module.database.rds_port
    dbname   = var.db_name
  })

  depends_on = [module.database]
}

# Add role attachment for ECS task to access secret
resource "aws_iam_role_policy_attachment" "ecs_task_secrets_access" {
  role       = module.ecs.task_execution_role_name  # Assuming you have this output from your ECS module
  policy_arn = module.database.secrets_access_policy_arn
}

module "ecr" {
  source = "./modules/ecr"
  
  repository_name = var.repository_name
}


module "ecs" {
  source = "./modules/ecs"
  
  vpc_id              = module.vpc.vpc_id
  subnet_ids          = module.vpc.subnet_ids
  ecs_task_sg_id      = module.security.ecs_task_sg_id
  alb_sg_id           = module.security.alb_sg_id
  
  aws_region     = var.aws_region
  repository_url = module.ecr.repository_url
  task_cpu       = var.task_cpu
  task_memory    = var.task_memory
  
  # Add these new parameters
  secret_name    = module.secrets.secret_name
  secret_arn     = module.secrets.secret_arn
  secrets_access_policy_arn = module.database.secrets_access_policy_arn  # Pass the policy ARN
  
  
  # You can still pass these for backward compatibility if needed
  db_username    = var.db_username
  db_password    = module.secrets.db_password
  db_endpoint    = module.database.rds_endpoint
  db_name        = var.db_name
  
  depends_on = [module.secrets]
}