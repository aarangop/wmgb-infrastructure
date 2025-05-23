# backend.tf
# Terraform backend configuration for remote state storage
# Requires manual setup of S3 bucket and DynamoDB table (see README.md)

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.98"
    }
  }

  # Remote backend configuration
  # The S3 bucket and DynamoDB table must be created manually first
  backend "s3" {
    bucket  = ""
    key     = ""
    region  = ""
    profile = ""
  }
}

# AWS Provider configuration
provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile

  # Default tags applied to all resources
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = terraform.workspace
      ManagedBy   = "terraform"
    }
  }
}
