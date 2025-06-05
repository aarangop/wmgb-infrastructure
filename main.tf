# main.tf - Root Module
# This is the main entry point for our infrastructure configuration.
# It orchestrates all the individual modules (s3, vpc, ecs, etc.) based on toggle variables.

# ==============================================================================
# DATA SOURCES
# ==============================================================================

# Get information about the current AWS account and caller
data "aws_caller_identity" "current" {}

# Get information about the current AWS region
data "aws_region" "current" {}

# ==============================================================================
# FEATURE TOGGLE VARIABLES
# ==============================================================================
# These variables allow us to enable/disable different parts of the infrastructure
# This lets us build and test incrementally without creating everything at once

variable "enable_s3" {
  description = "Enable S3 buckets for model storage"
  type        = bool
  default     = true
}

variable "enable_vpc" {
  description = "Enable VPC and networking resources"
  type        = bool
  default     = false
}

variable "enable_ecr" {
  description = "Enable ECR repositories for container images"
  type        = bool
  default     = false
}

variable "enable_ecs" {
  description = "Enable ECS cluster and services"
  type        = bool
  default     = false
}

variable "enable_iam" {
  description = "Enable IAM roles and policies"
  type        = bool
  default     = false
}

# ==============================================================================
# MODULE CONFIGURATIONS
# ==============================================================================

# S3 Module - Storage for ML models
module "s3" {
  # Only create if enabled
  count = var.enable_s3 ? 1 : 0

  source = "./modules/s3"

  # Pass configuration to the module
  project_name     = var.project_name
  environment_name = local.current_env.environment_name
  name_prefix      = local.name_prefix
  aws_region       = var.aws_region
  common_tags      = local.common_tags

  # Environment-specific settings
  enable_deletion_protection = local.current_env.enable_deletion_protection
}

# VPC Module - Networking infrastructure
module "vpc" {
  # Only create if enabled
  count = var.enable_vpc ? 1 : 0

  source = "./modules/vpc"

  # Pass configuration to the module
  project_name     = var.project_name
  environment_name = local.current_env.environment_name
  name_prefix      = local.name_prefix
  aws_region       = var.aws_region
  common_tags      = local.common_tags

  # Environment-specific VPC settings
  vpc_cidr           = local.current_env.vpc_cidr
  availability_zones = local.current_env.availability_zones
  enable_nat_gateway = local.current_env.enable_nat_gateway
  single_nat_gateway = local.current_env.single_nat_gateway
}

# ECR Module - Container registry
module "ecr" {
  count = var.enable_ecr ? 1 : 0

  source = "./modules/ecr"

  project_name     = var.project_name
  environment_name = local.current_env.environment_name
  name_prefix      = local.name_prefix
  common_tags      = local.common_tags
}

# ECS Module - Container orchestration
# module "ecs" {
#   count = var.enable_ecs ? 1 : 0
#   
#   source = "./modules/ecs"
#   
#   project_name     = var.project_name
#   environment_name = local.current_env.environment_name
#   name_prefix      = local.name_prefix
#   common_tags      = local.common_tags
#   
#   # Dependencies from other modules
#   vpc_id               = var.enable_vpc ? module.vpc[0].vpc_id : null
#   private_subnet_ids   = var.enable_vpc ? module.vpc[0].private_subnet_ids : []
#   ecr_repository_url   = var.enable_ecr ? module.ecr[0].repository_url : null
#   models_bucket_name   = var.enable_s3 ? module.s3[0].models_bucket_name : null
#   
#   # ECS-specific configuration
#   desired_count = local.current_env.ecs_desired_count
#   cpu          = local.current_env.ecs_cpu
#   memory       = local.current_env.ecs_memory
# }

# IAM Module - Permissions and roles
# module "iam" {
#   count = var.enable_iam ? 1 : 0
#   
#   source = "./modules/iam"
#   
#   project_name     = var.project_name
#   environment_name = local.current_env.environment_name
#   name_prefix      = local.name_prefix
#   common_tags      = local.common_tags
#   
#   # Resource ARNs for policy creation
#   models_bucket_arn = var.enable_s3 ? module.s3[0].models_bucket_arn : null
#   ecr_repository_arn = var.enable_ecr ? module.ecr[0].repository_arn : null
# }
