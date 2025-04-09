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

module "database" {
  source = "./modules/database"
  
  subnet_ids          = module.vpc.subnet_ids
  rds_sg_id           = module.security.rds_sg_id
  db_allocated_storage = var.db_allocated_storage
  db_instance_class   = var.db_instance_class
  db_name             = var.db_name
  db_username         = var.db_username
  db_password         = var.db_password
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
  repository_url      = module.ecr.repository_url
  db_endpoint         = module.database.rds_endpoint
  db_username         = module.database.db_username
  db_password         = module.database.db_password
  db_name             = module.database.db_name
  aws_region          = var.aws_region
  cluster_name        = var.cluster_name
  task_cpu            = var.task_cpu
  task_memory         = var.task_memory
  service_desired_count = var.service_desired_count
}