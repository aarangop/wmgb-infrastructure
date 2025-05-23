# This file exposes important information from all modules
# These outputs can be viewed with 'terraform output' command

# ==============================================================================
# ENVIRONMENT INFORMATION
# ==============================================================================

output "environment_info" {
  description = "Current environment configuration and workspace information"
  value = {
    # Workspace information
    workspace   = terraform.workspace
    environment = local.current_env.environment_name
    name_prefix = local.name_prefix

    # AWS information  
    aws_region     = var.aws_region
    aws_account_id = data.aws_caller_identity.current.account_id

    # Environment-specific configuration
    ecs_desired_count   = local.current_env.ecs_desired_count
    ecs_cpu             = local.current_env.ecs_cpu
    ecs_memory          = local.current_env.ecs_memory
    deletion_protection = local.current_env.enable_deletion_protection
  }
}

# ==============================================================================
# MODULE OUTPUTS
# ==============================================================================

# S3 Module outputs (only if S3 is enabled)
output "s3_info" {
  description = "Information about S3 resources from the S3 module"
  value       = var.enable_s3 ? module.s3[0].s3_resources_summary : null
}

output "models_bucket_name" {
  description = "Name of the models bucket (for use in application configuration)"
  value       = var.enable_s3 ? module.s3[0].models_bucket_name : null
}

output "models_bucket_arn" {
  description = "ARN of the models bucket (for use in IAM policies)"
  value       = var.enable_s3 ? module.s3[0].models_bucket_arn : null
}

# VPC Module outputs (will be enabled when VPC module is ready)
# output "vpc_info" {
#   description = "VPC and networking information"
#   value       = var.enable_vpc ? module.vpc[0].vpc_summary : "VPC module not enabled"
# }

# ECR Module outputs (will be enabled when ECR module is ready)
# output "ecr_info" {
#   description = "ECR repository information"
#   value       = var.enable_ecr ? module.ecr[0].repository_summary : "ECR module not enabled"
# }

# ECS Module outputs (will be enabled when ECS module is ready)
# output "ecs_info" {
#   description = "ECS cluster and service information"
#   value       = var.enable_ecs ? module.ecs[0].cluster_summary : "ECS module not enabled"
# }

# ==============================================================================
# FUTURE MODULE OUTPUTS
# ==============================================================================

# VPC outputs (will be uncommented when VPC module is created)
# output "vpc_info" {
#   description = "VPC and networking information"
#   value       = module.vpc.vpc_summary
# }

# ECR outputs (will be added when ECR module is created)
# output "ecr_info" {
#   description = "ECR repository information"  
#   value       = module.ecr.repository_summary
# }

# ECS outputs (will be added when ECS module is created)
# output "ecs_info" {
#   description = "ECS cluster and service information"
#   value       = module.ecs.cluster_summary
# }
