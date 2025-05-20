
resource "aws_s3_bucket" "model_bucket" {
    bucket = "whos-my-good-boy-models"
    tags = {
        Name = "Model Storage"
        Environment = "Development"
        Project = "WhosMyGoodBoy"
    }
}

resource "aws_s3_bucket_versioning" "model_bucket_versioning" {
    bucket = aws_s3_bucket.model_bucket.id

    versioning_configuration {
        status = "Enabled"
    }
}

# Security configuration
resource "aws_s3_bucket_public_access_block" "model_bucket_access" {
    bucket = aws_s3_bucket.model_bucket.id

    block_public_acls = true
    block_public_policy = true
    ignore_public_acls = true
    restrict_public_buckets = true
}

# Set up server-side encryption for the bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "model_bucket_encryption" {
  bucket = aws_s3_bucket.model_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

output "model_bucket_name" {
  value = aws_s3_bucket.model_bucket.id
}

output "model_bucket_arn" {
  value = aws_s3_bucket.model_bucket.arn
}