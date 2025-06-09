# modules/vpc/variables.tf
# Input variables for the VPC module

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
  description = "AWS region where VPC will be created"
  type        = string
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# ==============================================================================
# NETWORK CONFIGURATION
# ==============================================================================

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

variable "availability_zones" {
  description = "List of availability zones to use for subnets"
  type        = list(string)
  default     = [] # Will auto-detect if empty
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (explicit configuration preferred)"
  type        = list(string)
  default     = []

  validation {
    condition     = length(var.public_subnet_cidrs) == 0 || length(var.public_subnet_cidrs) >= 2
    error_message = "If specified, must provide at least 2 public subnet CIDRs for high availability."
  }
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (explicit configuration preferred)"
  type        = list(string)
  default     = []

  validation {
    condition     = length(var.private_subnet_cidrs) == 0 || length(var.private_subnet_cidrs) >= 2
    error_message = "If specified, must provide at least 2 private subnet CIDRs for high availability."
  }
}

# ==============================================================================
# FEATURE TOGGLES
# ==============================================================================

variable "enable_nat_gateway" {
  description = "Whether to create NAT Gateway for private subnets (recommended for prod)"
  type        = bool
  default     = false
}

variable "enable_vpc_flow_logs" {
  description = "Whether to enable VPC Flow Logs for network monitoring"
  type        = bool
  default     = false # Can be enabled for production
}

variable "single_nat_gateway" {
  description = "Use single NAT Gateway for all private subnets (cost optimization)"
  type        = bool
  default     = true # Set to false for high availability in prod
}

# ==============================================================================
# ENVIRONMENT-SPECIFIC OVERRIDES
# ==============================================================================

variable "enable_dns_hostnames" {
  description = "Whether to enable DNS hostnames in the VPC"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Whether to enable DNS support in the VPC"
  type        = bool
  default     = true
}
