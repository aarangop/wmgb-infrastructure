# modules/ecr/main.tf
# Creates ECR repositories for storing Docker container images

# ==============================================================================
# LOCAL VALUES
# ==============================================================================

locals {
  # Generate repository names with environment prefix
  repository_names = [for name in var.repository_names : "${var.name_prefix}-${name}"]
}

# ==============================================================================
# ECR REPOSITORIES
# ==============================================================================

# ECR repositories for storing container images
# Each repository can store multiple versions of a container image
resource "aws_ecr_repository" "repositories" {
  count = length(var.repository_names)

  name                 = local.repository_names[count.index]
  image_tag_mutability = var.image_tag_mutability

  # Enable vulnerability scanning on push
  # This scans images for known security vulnerabilities
  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  # Encryption configuration
  # Images are encrypted at rest using AWS managed keys
  encryption_configuration {
    encryption_type = "AES256" # AWS managed encryption (no additional cost)
  }

  # Allow force deletion if enabled (useful for dev environments)
  force_delete = var.enable_force_delete

  tags = merge(var.common_tags, {
    Name        = local.repository_names[count.index]
    Purpose     = "container-registry"
    Repository  = var.repository_names[count.index]
    Description = "Container images for ${var.repository_names[count.index]} service"
  })
}

# ==============================================================================
# LIFECYCLE POLICIES
# ==============================================================================

# Lifecycle policies automatically clean up old images to control costs
# This prevents ECR storage from growing indefinitely
resource "aws_ecr_lifecycle_policy" "repositories" {
  count = length(aws_ecr_repository.repositories)

  repository = aws_ecr_repository.repositories[count.index].name

  # JSON policy defining cleanup rules
  policy = jsonencode({
    rules = [
      {
        # Rule 1: Keep only the most recent tagged images
        rulePriority = 1
        description  = "Keep last ${var.max_image_count} tagged images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["latest", "main", "master", "develop"]
          countType     = "imageCountMoreThan"
          countNumber   = var.max_image_count
        }
        action = {
          type = "expire"
        }
      },
      {
        # Rule 2: Keep production images longer
        rulePriority = 2
        description  = "Keep last ${var.max_production_images} production images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = var.production_tag_prefixes
          countType     = "imageCountMoreThan"
          countNumber   = var.max_production_images
        }
        action = {
          type = "expire"
        }
      },
      {
        # Rule 3: Clean up untagged images quickly
        rulePriority = 3
        description  = "Delete untagged images older than ${var.max_untagged_image_days} days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = var.max_untagged_image_days
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
