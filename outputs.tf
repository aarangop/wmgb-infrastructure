# outputs.tf
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

    # GitHub configuration
    github_org         = var.github_org
    backend_repository = var.backend_repository
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

# VPC Module outputs (only if VPC is enabled)
output "vpc_info" {
  description = "VPC and networking information"
  value       = var.enable_vpc ? module.vpc[0].vpc_summary : null
}

# ECR Module outputs (only if ECR is enabled)
output "ecr_info" {
  description = "ECR repository information"
  value       = var.enable_ecr ? module.ecr[0].ecr_summary : null
}

output "ecr_repository_url" {
  description = "ECR repository URL for the backend (for CI/CD)"
  value       = var.enable_ecr ? module.ecr[0].backend_repository_url : null
}

# ECS Module outputs (only if ECS is enabled)
output "ecs_info" {
  description = "ECS cluster and service information"
  value       = var.enable_ecs ? module.ecs[0].ecs_summary : null
}

output "application_url" {
  description = "URL to access the deployed application"
  value       = var.enable_ecs ? module.ecs[0].application_url : null
}

# IAM Module outputs (only if IAM is enabled)
output "iam_info" {
  description = "IAM and OIDC configuration for GitHub Actions"
  value       = var.enable_iam ? module.iam[0].iam_summary : null
}

output "github_actions_role_arn" {
  description = "ARN of the GitHub Actions deployment role (for CI/CD configuration)"
  value       = var.enable_iam ? module.iam[0].github_actions_role_arn : null
}

output "github_actions_readonly_role_arn" {
  description = "ARN of the GitHub Actions read-only role (for testing)"
  value       = var.enable_iam ? module.iam[0].github_actions_readonly_role_arn : null
}

# ==============================================================================
# CI/CD CONFIGURATION HELPER
# ==============================================================================

output "github_actions_config" {
  description = "Configuration values needed for GitHub Actions workflows"
  value = {
    # AWS Configuration
    aws_region     = var.aws_region
    aws_account_id = data.aws_caller_identity.current.account_id

    # IAM Roles
    deployment_role_arn = var.enable_iam ? module.iam[0].github_actions_role_arn : "IAM module not enabled"
    readonly_role_arn   = var.enable_iam ? module.iam[0].github_actions_readonly_role_arn : "IAM module not enabled"

    # ECR Configuration
    ecr_repository_url = var.enable_ecr ? module.ecr[0].backend_repository_url : "ECR module not enabled"

    # ECS Configuration
    ecs_cluster_name = var.enable_ecs ? module.ecs[0].cluster_name : "ECS module not enabled"
    ecs_service_name = var.enable_ecs ? module.ecs[0].service_name : "ECS module not enabled"

    # S3 Configuration
    models_bucket_name = var.enable_s3 ? module.s3[0].models_bucket_name : "S3 module not enabled"

    # Environment Configuration
    environment    = local.current_env.environment_name
    name_prefix    = local.name_prefix
    container_name = "backend" # Standard container name

    # GitHub Repository Info
    github_org  = var.github_org
    github_repo = var.backend_repository
  }
  sensitive = false
}

# ==============================================================================
# DEPLOYMENT READINESS CHECK
# ==============================================================================

output "deployment_readiness" {
  description = "Check if all required components are ready for deployment"
  value = {
    s3_ready  = var.enable_s3
    vpc_ready = var.enable_vpc
    ecr_ready = var.enable_ecr
    ecs_ready = var.enable_ecs
    iam_ready = var.enable_iam

    ready_for_deployment = var.enable_s3 && var.enable_vpc && var.enable_ecr && var.enable_ecs && var.enable_iam

    next_steps = var.enable_s3 && var.enable_vpc && var.enable_ecr && var.enable_ecs && var.enable_iam ? [
      "All infrastructure components are ready!",
      "Configure GitHub repository secrets with the role ARNs from github_actions_config output",
      "Update your GitHub Actions workflows to use OIDC authentication",
      "Push to your main branch to trigger deployment"
      ] : [
      var.enable_s3 ? "✓ S3 bucket created" : "❌ Enable S3 module",
      var.enable_vpc ? "✓ VPC configured" : "❌ Enable VPC module",
      var.enable_ecr ? "✓ ECR repository created" : "❌ Enable ECR module",
      var.enable_ecs ? "✓ ECS cluster ready" : "❌ Enable ECS module",
      var.enable_iam ? "✓ IAM roles configured" : "❌ Enable IAM module"
    ]
  }
}
