# Root module variables
# These define the core variables needed across all environments

variable "region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-2"
}

variable "aws_profile" {
  description = "AWS credentials profile to use"
  type        = string
  default     = "whos-my-good-boy-infra"
}

variable "environment" {
  description = "Deployment environment (prod or dev)"
  type        = string
  default     = "prod"
}

# Common tags to be applied to all resources
variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Project = "WhosMyGoodBoy"
  }
}
