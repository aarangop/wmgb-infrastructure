# Production environment outputs

# S3 outputs
output "terraform_state_bucket" {
  description = "ID of the Terraform state bucket"
  value       = module.s3.terraform_state_bucket_id
}

output "terraform_state_bucket_arn" {
  description = "ARN of the Terraform state bucket"
  value       = module.s3.terraform_state_bucket_arn
}

output "ml_models_bucket" {
  description = "ID of the ML models bucket"
  value       = module.s3.ml_models_bucket_id
}

output "ml_models_bucket_arn" {
  description = "ARN of the ML models bucket"
  value       = module.s3.ml_models_bucket_arn
}

# VPC outputs
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "lb_security_group_id" {
  description = "ID of the load balancer security group"
  value       = module.vpc.lb_security_group_id
}

output "ecs_tasks_security_group_id" {
  description = "ID of the ECS tasks security group"
  value       = module.vpc.ecs_tasks_security_group_id
}
