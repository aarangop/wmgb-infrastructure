# modules/iam/outputs.tf
# Outputs from the IAM module

# ==============================================================================
# OIDC PROVIDER INFORMATION
# ==============================================================================

output "oidc_provider_arn" {
  description = "ARN of the GitHub OIDC provider"
  value       = local.oidc_provider_arn
}

output "oidc_provider_url" {
  description = "URL of the GitHub OIDC provider"
  value       = "https://token.actions.githubusercontent.com"
}

# ==============================================================================
# IAM ROLES INFORMATION
# ==============================================================================

output "github_actions_role_arn" {
  description = "ARN of the main GitHub Actions deployment role"
  value       = aws_iam_role.github_actions_role.arn
}

output "github_actions_role_name" {
  description = "Name of the main GitHub Actions deployment role"
  value       = aws_iam_role.github_actions_role.name
}

output "github_actions_readonly_role_arn" {
  description = "ARN of the read-only GitHub Actions role"
  value       = aws_iam_role.github_actions_readonly_role.arn
}

output "github_actions_readonly_role_name" {
  description = "Name of the read-only GitHub Actions role"
  value       = aws_iam_role.github_actions_readonly_role.name
}

# ==============================================================================
# IAM POLICIES INFORMATION
# ==============================================================================

output "ecr_policy_arn" {
  description = "ARN of the ECR access policy"
  value       = aws_iam_policy.github_ecr_policy.arn
}

output "ecs_policy_arn" {
  description = "ARN of the ECS deployment policy"
  value       = aws_iam_policy.github_ecs_policy.arn
}

output "s3_policy_arn" {
  description = "ARN of the S3 access policy"
  value       = aws_iam_policy.github_s3_policy.arn
}

# ==============================================================================
# CONFIGURATION SUMMARY
# ==============================================================================

output "iam_summary" {
  description = "Summary of IAM configuration for GitHub Actions"
  value = {
    # Basic information
    environment = var.environment_name
    github_org  = var.github_org
    github_repo = var.github_repo

    # OIDC configuration
    oidc_provider_arn = local.oidc_provider_arn
    oidc_provider_url = "https://token.actions.githubusercontent.com"
    oidc_created      = var.create_oidc_provider

    # Roles
    deployment_role = {
      arn  = aws_iam_role.github_actions_role.arn
      name = aws_iam_role.github_actions_role.name
    }
    readonly_role = {
      arn  = aws_iam_role.github_actions_readonly_role.arn
      name = aws_iam_role.github_actions_readonly_role.name
    }

    # Policies
    policies = {
      ecr = aws_iam_policy.github_ecr_policy.arn
      ecs = aws_iam_policy.github_ecs_policy.arn
      s3  = aws_iam_policy.github_s3_policy.arn
    }

    # Trust relationships
    trusted_repos  = ["${var.github_org}/${var.github_repo}"]
    ecr_repository = var.ecr_repository_arn

    # Metadata
    created_by     = "terraform"
    module_version = "1.0"
  }
}

# ==============================================================================
# GITHUB ACTIONS INTEGRATION INFO
# ==============================================================================

output "github_actions_config" {
  description = "Configuration values for GitHub Actions workflows"
  value = {
    # Role ARNs for workflows
    deployment_role_arn = aws_iam_role.github_actions_role.arn
    readonly_role_arn   = aws_iam_role.github_actions_readonly_role.arn

    # AWS configuration
    aws_region = var.aws_region

    # Repository permissions
    can_push_to_ecr   = true
    can_deploy_to_ecs = true
    can_access_s3     = true

    # Environment-specific info
    environment = var.environment_name
    name_prefix = var.name_prefix

    # OIDC info
    oidc_provider_arn = local.oidc_provider_arn
    oidc_created_here = var.create_oidc_provider
  }
}
