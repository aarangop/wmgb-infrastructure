# Development environment configuration

locals {
  environment    = "dev"
  project_prefix = "wmgb-dev"
}

# VPC Module
module "vpc" {
  source = "../../modules/vpc"

  vpc_cidr             = var.vpc_cidr
  public_subnet_1_cidr = var.public_subnet_1_cidr
  public_subnet_2_cidr = var.public_subnet_2_cidr
  availability_zones   = var.availability_zones
  project_prefix       = local.project_prefix
  api_port             = var.api_port
  common_tags = merge(
    var.common_tags,
    {
      Environment = local.environment
    }
  )
}

# S3 Module - for Terraform state and ML models
module "s3" {
  source = "../../modules/s3"

  project_prefix          = local.project_prefix
  enable_model_versioning = true
  common_tags = merge(
    var.common_tags,
    {
      Environment = local.environment
    }
  )
}

# ECS configuration - module will be added in next step
# ECR configuration - module will be added in next step
# IAM configuration - module will be added in next step
# ELB configuration - module will be added in next step
