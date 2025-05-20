# ecr.tf
resource "aws_ecr_repository" "backend_repo" {
  name                 = "wmgb-backend"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Project     = "WhosMyGoodBoy"
    Environment = "Production"
  }
}

# Enable ECR image retention policy (optional)
resource "aws_ecr_lifecycle_policy" "backend_lifecycle_policy" {
  repository = aws_ecr_repository.backend_repo.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep only 5 images"
      action = {
        type = "expire"
      }
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 5
      }
    }]
  })
}

# Outputs
output "ecr_repository_url" {
  value       = aws_ecr_repository.backend_repo.repository_url
  description = "The URL of the ECR repository"
}
