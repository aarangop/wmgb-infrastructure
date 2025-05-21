# S3 Backend Configuration

terraform {
  backend "s3" {
    bucket  = "wmgb-terraform-state"
    key     = "terraform.tfstate" # This will be overridden using the -backend-config flag
    region  = "us-east-2"
    encrypt = true
    # dynamodb_table = "wmgb-terraform-locks" # Uncomment if you want to use DynamoDB for state locking
  }
}
