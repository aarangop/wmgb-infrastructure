# Global project configuration

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "whos-my-good-boy"
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
    }

    production = {
      environment_name = "prod"
      # More robust settings for prod
      ecs_desired_count = 2
      ecs_cpu           = 512
      ecs_memory        = 1024
      # Prevent accidental deletion
      enable_deletion_protection = true
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
