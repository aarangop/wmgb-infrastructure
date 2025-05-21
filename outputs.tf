# Root module outputs
# These will expose the key outputs from our infrastructure

output "environment" {
  description = "The environment that was deployed"
  value       = var.environment
}

# Use a local value to simplify accessing module outputs
locals {
  # This will contain the active environment module's outputs
  env = var.environment == "prod" ? module.prod[0] : module.dev[0]
}

# S3 outputs
output "terraform_state_bucket" {
  description = "ID of the Terraform state bucket"
  value       = local.env.terraform_state_bucket
}

output "terraform_state_bucket_arn" {
  description = "ARN of the Terraform state bucket"
  value       = local.env.terraform_state_bucket_arn
}

output "ml_models_bucket" {
  description = "ID of the ML models bucket"
  value       = local.env.ml_models_bucket
}

output "ml_models_bucket_arn" {
  description = "ARN of the ML models bucket"
  value       = local.env.ml_models_bucket_arn
}

# VPC outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = local.env.vpc_id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = local.env.public_subnet_ids
}

output "lb_security_group_id" {
  description = "ID of the load balancer security group"
  value       = local.env.lb_security_group_id
}

output "ecs_tasks_security_group_id" {
  description = "ID of the ECS tasks security group"
  value       = local.env.ecs_tasks_security_group_id
}
