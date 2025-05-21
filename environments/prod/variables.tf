# Production environment variables

# VPC variables
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_1_cidr" {
  description = "CIDR block for the first public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "public_subnet_2_cidr" {
  description = "CIDR block for the second public subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "availability_zones" {
  description = "List of availability zones to use"
  type        = list(string)
  default     = ["us-east-2a", "us-east-2b"]
}

# API configuration
variable "api_port" {
  description = "Port for the API service"
  type        = number
  default     = 8000
}

# ECS task configuration
variable "service_desired_count" {
  description = "Desired number of tasks to run"
  type        = number
  default     = 2
}

# Common tags to be applied to all resources
variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Project = "WhosMyGoodBoy"
  }
}
