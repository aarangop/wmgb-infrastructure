# modules/iam/variables.tf
# Input variables for the IAM module

# ==============================================================================
# REQUIRED VARIABLES
# ==============================================================================

variable "project_name" {
  description = "Name of the project (used for resource naming)"
  type        = string
}

variable "environment_name" {
  description = "Environment name (dev, prod, staging)"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for naming resources (typically project-environment)"
  type        = string
}

variable "aws_region" {
  description = "AWS region where resources are located"
  type        = string
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# ==============================================================================
# OIDC PROVIDER CONFIGURATION
# ==============================================================================

variable "create_oidc_provider" {
  description = "Whether to create the OIDC provider (should be true for first environment, false for subsequent)"
  type        = bool
  default     = true
}

# ==============================================================================
# GITHUB CONFIGURATION
# ==============================================================================

variable "github_org" {
  description = "GitHub organization or username"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name (backend repository)"
  type        = string
}

# ==============================================================================
# RESOURCE DEPENDENCIES
# ==============================================================================

variable "ecr_repository_arn" {
  description = "ECR repository ARN that GitHub Actions can access"
  type        = string
}

variable "models_bucket_arn" {
  description = "ARN of the S3 models bucket"
  type        = string
}
