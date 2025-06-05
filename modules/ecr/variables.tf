# modules/ecr/variables.tf
# Input variables for the ECR module

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

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# ==============================================================================
# ECR CONFIGURATION
# ==============================================================================

variable "repository_names" {
  description = "List of ECR repository names to create"
  type        = list(string)
  default     = ["backend"] # Can add frontend, worker, etc. later
}

variable "image_tag_mutability" {
  description = "Image tag mutability setting (MUTABLE or IMMUTABLE)"
  type        = string
  default     = "MUTABLE"

  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.image_tag_mutability)
    error_message = "Image tag mutability must be either MUTABLE or IMMUTABLE."
  }
}

variable "scan_on_push" {
  description = "Enable vulnerability scanning on image push"
  type        = bool
  default     = true # Recommended for security
}

# ==============================================================================
# LIFECYCLE POLICY CONFIGURATION
# ==============================================================================

variable "max_image_count" {
  description = "Maximum number of images to keep in repository"
  type        = number
  default     = 10 # Optimized for hobby projects - balance between rollback capability and cost
}

variable "max_untagged_image_days" {
  description = "Days to keep untagged images before deletion"
  type        = number
  default     = 1 # Clean up build artifacts quickly
}

variable "production_tag_prefixes" {
  description = "Tag patterns for production images (kept longer)"
  type        = list(string)
  default     = ["prod-", "release-", "v"]
}

variable "max_production_images" {
  description = "Maximum number of production-tagged images to keep"
  type        = number
  default     = 10 # Keep more production releases for rollback
}

# ==============================================================================
# ACCESS CONTROL
# ==============================================================================

variable "enable_force_delete" {
  description = "Allow deletion of repository even if it contains images"
  type        = bool
  default     = false # Safety default - require manual cleanup
}
