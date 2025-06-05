# variables.tf
# Global project configuration

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

# Environment-specific configurations
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
      # VPC settings - simple and cost optimized
      enable_nat_gateway = false # Start simple, add later if needed
      single_nat_gateway = true
      vpc_cidr           = "10.0.0.0/16"
      availability_zones = [] # Use first 2 AZs auto-detected
    }

    production = {
      environment_name = "prod"
      # More robust settings for prod
      ecs_desired_count = 2
      ecs_cpu           = 512
      ecs_memory        = 1024
      # Prevent accidental deletion
      enable_deletion_protection = true
      # VPC settings - simple for now, can enable NAT later
      enable_nat_gateway = false # Start simple, enable when needed
      single_nat_gateway = true  # When enabled, use single for cost
      vpc_cidr           = "10.1.0.0/16"
      availability_zones = [] # Use first 2 AZs auto-detected
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
  }
}
