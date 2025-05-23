# modules/s3/main.tf
# Creates S3 bucket for storing machine learning models
# This module handles environment-specific model storage

# ==============================================================================
# LOCAL VALUES
# ==============================================================================

locals {
  # Generate the models bucket name using the standard naming convention
  models_bucket_name = "${var.name_prefix}-models"
}

# ==============================================================================
# MODELS BUCKET
# ==============================================================================

# Main S3 bucket for storing ML models
# Each environment (dev/prod) gets its own bucket
resource "aws_s3_bucket" "models" {
  bucket = local.models_bucket_name

  tags = merge(var.common_tags, {
    Name        = local.models_bucket_name
    Purpose     = "ml-models"
    Description = "Stores machine learning models for ${var.environment_name} environment"
  })
}

# ==============================================================================
# BUCKET CONFIGURATION
# ==============================================================================

# Enable versioning to track different versions of ML models
# This allows rollback to previous models if needed
resource "aws_s3_bucket_versioning" "models" {
  bucket = aws_s3_bucket.models.id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

# Configure server-side encryption
# All objects stored in the bucket will be automatically encrypted
resource "aws_s3_bucket_server_side_encryption_configuration" "models" {
  bucket = aws_s3_bucket.models.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256" # AWS managed encryption
    }
    # Use bucket keys to reduce encryption costs
    bucket_key_enabled = true
  }
}

# Block all public access to the models bucket
# ML models should never be publicly accessible
resource "aws_s3_bucket_public_access_block" "models" {
  bucket = aws_s3_bucket.models.id

  # Block all forms of public access
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ==============================================================================
# LIFECYCLE MANAGEMENT
# ==============================================================================

# Configure lifecycle rules to manage storage costs
# Old model versions are moved to cheaper storage or deleted automatically
resource "aws_s3_bucket_lifecycle_configuration" "models" {
  # Only create lifecycle rules if versioning is enabled
  count  = var.enable_versioning ? 1 : 0
  bucket = aws_s3_bucket.models.id

  rule {
    id     = "models_lifecycle"
    status = "Enabled"

    # Apply to all objects in the bucket (empty filter = all objects)
    filter {
      prefix = ""
    }

    # Move non-current versions to Infrequent Access storage after specified days
    # This reduces costs for older model versions
    noncurrent_version_transition {
      noncurrent_days = var.lifecycle_days_to_ia
      storage_class   = "STANDARD_IA"
    }

    # Delete non-current versions after specified days (if configured)
    # Set lifecycle_days_to_delete to 0 to keep versions indefinitely
    dynamic "noncurrent_version_expiration" {
      for_each = var.lifecycle_days_to_delete > 0 ? [1] : []

      content {
        noncurrent_days = var.lifecycle_days_to_delete
      }
    }
  }
}

# ==============================================================================
# BUCKET NOTIFICATION (Optional - for future use)
# ==============================================================================

# Placeholder for future bucket notifications
# Could be used to trigger Lambda functions when new models are uploaded
# resource "aws_s3_bucket_notification" "models" {
#   bucket = aws_s3_bucket.models.id
#   
#   # Example: notify when new models are uploaded
#   # lambda_function {
#   #   lambda_function_arn = var.model_processing_lambda_arn
#   #   events              = ["s3:ObjectCreated:*"]
#   #   filter_prefix       = "models/"
#   # }
# }
