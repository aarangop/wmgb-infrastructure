# modules/s3/outputs.tf
# Outputs from the S3 module that other modules can reference
# These values are used by ECS tasks, IAM policies, and application configuration

# ==============================================================================
# MODELS BUCKET OUTPUTS
# ==============================================================================

output "models_bucket_name" {
  description = "Name of the models bucket"
  value       = aws_s3_bucket.models.bucket
}

output "models_bucket_arn" {
  description = "ARN of the models bucket (used for IAM policies)"
  value       = aws_s3_bucket.models.arn
}

output "models_bucket_id" {
  description = "ID of the models bucket"
  value       = aws_s3_bucket.models.id
}

output "models_bucket_domain_name" {
  description = "Domain name of the models bucket"
  value       = aws_s3_bucket.models.bucket_domain_name
}

output "models_bucket_regional_domain_name" {
  description = "Regional domain name of the models bucket"
  value       = aws_s3_bucket.models.bucket_regional_domain_name
}

# ==============================================================================
# CONFIGURATION OUTPUTS
# ==============================================================================

output "bucket_region" {
  description = "Region where the bucket is located"
  value       = aws_s3_bucket.models.region
}

output "versioning_enabled" {
  description = "Whether versioning is enabled on the bucket"
  value       = var.enable_versioning
}

output "encryption_enabled" {
  description = "Whether encryption is enabled on the bucket"
  value       = true # Always true in our configuration
}

# ==============================================================================
# SUMMARY OUTPUT
# ==============================================================================

output "s3_resources_summary" {
  description = "Summary of all S3 resources created by this module"
  value = {
    # Bucket information
    bucket_name   = aws_s3_bucket.models.bucket
    bucket_arn    = aws_s3_bucket.models.arn
    bucket_region = aws_s3_bucket.models.region

    # Configuration
    environment         = var.environment_name
    versioning_enabled  = var.enable_versioning
    encryption_enabled  = true
    deletion_protection = var.enable_deletion_protection

    # Lifecycle settings
    lifecycle_ia_days     = var.lifecycle_days_to_ia
    lifecycle_delete_days = var.lifecycle_days_to_delete

    # Metadata
    created_by     = "terraform"
    module_version = "1.0"
  }
}
