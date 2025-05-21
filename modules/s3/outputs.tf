# S3 module outputs

# Terraform state bucket outputs
output "terraform_state_bucket_id" {
  description = "The name of the Terraform state bucket"
  value       = aws_s3_bucket.terraform_state.id
}

output "terraform_state_bucket_arn" {
  description = "The ARN of the Terraform state bucket"
  value       = aws_s3_bucket.terraform_state.arn
}

output "terraform_state_bucket_domain_name" {
  description = "The domain name of the Terraform state bucket"
  value       = aws_s3_bucket.terraform_state.bucket_domain_name
}

# ML models bucket outputs
output "ml_models_bucket_id" {
  description = "The name of the ML models bucket"
  value       = aws_s3_bucket.ml_models.id
}

output "ml_models_bucket_arn" {
  description = "The ARN of the ML models bucket"
  value       = aws_s3_bucket.ml_models.arn
}

output "ml_models_bucket_domain_name" {
  description = "The domain name of the ML models bucket"
  value       = aws_s3_bucket.ml_models.bucket_domain_name
}
