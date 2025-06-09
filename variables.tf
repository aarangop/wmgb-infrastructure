# variables.tf
# Global project configuration - values should be provided via terraform.tfvars

# ==============================================================================
# PROJECT CONFIGURATION VARIABLES
# ==============================================================================

variable "project_name" {
  description = "Name of the project"
  type        = string
  # No default - must be provided via terraform.tfvars or environment variable

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  # No default - must be provided via terraform.tfvars or environment variable
}

variable "aws_profile" {
  description = "AWS CLI profile to use"
  type        = string
  # No default - must be provided via terraform.tfvars or environment variable
}

# ==============================================================================
# GITHUB CONFIGURATION VARIABLES
# ==============================================================================

variable "github_org" {
  description = "GitHub organization or username"
  type        = string
  # No default - must be provided via terraform.tfvars

  validation {
    condition     = length(var.github_org) > 0
    error_message = "GitHub organization cannot be empty."
  }
}

variable "backend_repository" {
  description = "Name of the backend repository (e.g., 'wmgb-backend')"
  type        = string
  # No default - must be provided via terraform.tfvars

  validation {
    condition     = can(regex("^[a-zA-Z0-9._-]+$", var.backend_repository))
    error_message = "Repository name must contain only letters, numbers, periods, hyphens, and underscores."
  }
}

variable "infrastructure_repository" {
  description = "Name of the infrastructure repository (e.g., 'wmgb-infrastructure')"
  type        = string
  default     = ""
  # Optional - only needed if you want separate CI/CD for infrastructure
}

# ==============================================================================
# ENVIRONMENT CONFIGURATION
# ==============================================================================

# Environment-specific configurations with explicit CIDR ranges
locals {
  # Environment settings based on workspace
  environment_config = {
    development = {
      environment_name = "dev"
      # Lightweight settings for dev
      ecs_desired_count = 1
      ecs_cpu           = 256
      ecs_memory        = 512
      # Allow easy shutdown
      enable_deletion_protection = false
      # VPC settings - explicit and clear
      enable_nat_gateway = false # Start simple, add later if needed
      single_nat_gateway = true
      vpc_cidr           = "10.0.0.0/16"
      availability_zones = [] # Use first 2 AZs auto-detected
      # Explicit subnet ranges for development
      public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
      private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]
    }

    production = {
      environment_name = "prod"
      # More robust settings for prod
      ecs_desired_count = 2
      ecs_cpu           = 512
      ecs_memory        = 1024
      # Prevent accidental deletion
      enable_deletion_protection = true
      # VPC settings - explicit and clear
      enable_nat_gateway = false # Start simple, enable when needed
      single_nat_gateway = true  # When enabled, use single for cost
      vpc_cidr           = "10.1.0.0/16"
      availability_zones = [] # Use first 2 AZs auto-detected
      # Explicit subnet ranges for production
      public_subnet_cidrs  = ["10.1.1.0/24", "10.1.2.0/24"]
      private_subnet_cidrs = ["10.1.11.0/24", "10.1.12.0/24"]
    }

    staging = {
      environment_name = "staging"
      # Mid-level settings for staging
      ecs_desired_count = 1
      ecs_cpu           = 256
      ecs_memory        = 512
      # Allow deletion for testing
      enable_deletion_protection = false
      # VPC settings - explicit and clear
      enable_nat_gateway = false
      single_nat_gateway = true
      vpc_cidr           = "10.2.0.0/16"
      availability_zones = []
      # Explicit subnet ranges for staging
      public_subnet_cidrs  = ["10.2.1.0/24", "10.2.2.0/24"]
      private_subnet_cidrs = ["10.2.11.0/24", "10.2.12.0/24"]
    }
  }

  # Select configuration based on current workspace
  current_env = local.environment_config[terraform.workspace]

  # Common naming convention
  name_prefix = "${var.project_name}-${local.current_env.environment_name}"

  # Common tags
  common_tags = {
    Project     = var.project_name
    Environment = local.current_env.environment_name
    Workspace   = terraform.workspace
    ManagedBy   = "terraform"
    Repository  = var.backend_repository
  }
}
