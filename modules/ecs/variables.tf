# modules/ecs/variables.tf
# Input variables for the ECS module

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
# NETWORK DEPENDENCIES (from VPC module)
# ==============================================================================

variable "vpc_id" {
  description = "ID of the VPC where ECS resources will be created"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for ECS tasks"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for load balancer"
  type        = list(string)
}

variable "ecs_security_group_id" {
  description = "Security group ID for ECS tasks"
  type        = string
}

variable "alb_security_group_id" {
  description = "Security group ID for Application Load Balancer"
  type        = string
}

# ==============================================================================
# CONTAINER DEPENDENCIES (from ECR module)
# ==============================================================================

variable "ecr_repository_url" {
  description = "ECR repository URL for container images"
  type        = string
}

variable "container_image_tag" {
  description = "Tag for the container image to deploy"
  type        = string
  default     = "latest"
}

# ==============================================================================
# STORAGE DEPENDENCIES (from S3 module)
# ==============================================================================

variable "models_bucket_name" {
  description = "Name of the S3 bucket containing ML models"
  type        = string
}

# ==============================================================================
# ECS CONFIGURATION
# ==============================================================================

variable "cluster_name" {
  description = "Name of the ECS cluster (optional, defaults to name_prefix-cluster)"
  type        = string
  default     = ""
}

variable "service_name" {
  description = "Name of the ECS service (optional, defaults to backend)"
  type        = string
  default     = "backend"
}

variable "task_cpu" {
  description = "CPU units for the task (256, 512, 1024, 2048, 4096)"
  type        = number
  default     = 256

  validation {
    condition     = contains([256, 512, 1024, 2048, 4096], var.task_cpu)
    error_message = "Task CPU must be one of: 256, 512, 1024, 2048, 4096."
  }
}

variable "task_memory" {
  description = "Memory for the task in MB (must be compatible with CPU)"
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "Desired number of task instances"
  type        = number
  default     = 1

  validation {
    condition     = var.desired_count >= 0 && var.desired_count <= 10
    error_message = "Desired count must be between 0 and 10."
  }
}

variable "container_port" {
  description = "Port that the container listens on"
  type        = number
  default     = 8000 # FastAPI default
}

variable "health_check_path" {
  description = "Path for health check endpoint"
  type        = string
  default     = "/health" # Common health check endpoint
}

# ==============================================================================
# LOAD BALANCER CONFIGURATION
# ==============================================================================

variable "enable_load_balancer" {
  description = "Whether to create an Application Load Balancer"
  type        = bool
  default     = true
}

variable "load_balancer_type" {
  description = "Type of load balancer (application or network)"
  type        = string
  default     = "application"

  validation {
    condition     = contains(["application", "network"], var.load_balancer_type)
    error_message = "Load balancer type must be either 'application' or 'network'."
  }
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection on the load balancer"
  type        = bool
  default     = false
}

# ==============================================================================
# ENVIRONMENT VARIABLES
# ==============================================================================

variable "environment_variables" {
  description = "Environment variables for the container"
  type        = map(string)
  default     = {}
}

variable "secrets" {
  description = "Secrets for the container (stored in AWS Parameter Store or Secrets Manager)"
  type        = map(string)
  default     = {}
}

# ==============================================================================
# LOGGING CONFIGURATION
# ==============================================================================

variable "enable_logging" {
  description = "Enable CloudWatch logging for containers"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "CloudWatch log retention period in days"
  type        = number
  default     = 7 # Cost-optimized for hobby projects

  validation {
    condition = contains([
      1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653
    ], var.log_retention_days)
    error_message = "Log retention days must be a valid CloudWatch retention period."
  }
}

# ==============================================================================
# AUTO SCALING CONFIGURATION
# ==============================================================================

variable "enable_auto_scaling" {
  description = "Enable auto scaling for the ECS service"
  type        = bool
  default     = false # Keep simple for hobby projects
}

variable "min_capacity" {
  description = "Minimum number of tasks for auto scaling"
  type        = number
  default     = 1
}

variable "max_capacity" {
  description = "Maximum number of tasks for auto scaling"
  type        = number
  default     = 4
}

# ==============================================================================
# DEPLOYMENT CONFIGURATION
# ==============================================================================

variable "deployment_maximum_percent" {
  description = "Upper limit on number of running tasks during deployment (as percentage of desired_count)"
  type        = number
  default     = 200

  validation {
    condition     = var.deployment_maximum_percent >= 100 && var.deployment_maximum_percent <= 1000
    error_message = "Deployment maximum percent must be between 100 and 1000."
  }
}

variable "deployment_minimum_healthy_percent" {
  description = "Lower limit on number of healthy tasks during deployment (as percentage of desired_count)"
  type        = number
  default     = 50

  validation {
    condition     = var.deployment_minimum_healthy_percent >= 0 && var.deployment_minimum_healthy_percent <= 100
    error_message = "Deployment minimum healthy percent must be between 0 and 100."
  }
}
