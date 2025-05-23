# modules/s3/variables.tf
# Input variables for the S3 module - defines what the module needs from the root module

# ==============================================================================
# REQUIRED VARIABLES
# ==============================================================================

variable "project_name" {
  description = "Name of the project (used for resource naming)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "environment_name" {
  description = "Environment name (dev, prod, staging)"
  type        = string

  validation {
    condition     = contains(["dev", "prod", "staging"], var.environment_name)
    error_message = "Environment name must be one of: dev, prod, staging."
  }
}

variable "name_prefix" {
  description = "Prefix for naming resources (typically project-environment)"
  type        = string
}

variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# ==============================================================================
# OPTIONAL CONFIGURATION
# ==============================================================================

variable "enable_deletion_protection" {
  description = "Whether to enable deletion protection (recommended for prod)"
  type        = bool
  default     = true
}

variable "enable_versioning" {
  description = "Whether to enable versioning on the models bucket"
  type        = bool
  default     = true
}

variable "lifecycle_days_to_ia" {
  description = "Days after which to transition old versions to Infrequent Access"
  type        = number
  default     = 30
}

variable "lifecycle_days_to_delete" {
  description = "Days after which to delete old versions (0 = never delete)"
  type        = number
  default     = 90
}
