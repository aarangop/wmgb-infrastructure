# modules/ecr/outputs.tf
# Outputs from the ECR module that other modules can reference

# ==============================================================================
# REPOSITORY INFORMATION
# ==============================================================================

output "repository_urls" {
  description = "Map of repository names to their URLs"
  value = {
    for i, repo in aws_ecr_repository.repositories :
    var.repository_names[i] => repo.repository_url
  }
}

output "repository_arns" {
  description = "Map of repository names to their ARNs"
  value = {
    for i, repo in aws_ecr_repository.repositories :
    var.repository_names[i] => repo.arn
  }
}

output "repository_names" {
  description = "List of ECR repository names (with environment prefix)"
  value       = [for repo in aws_ecr_repository.repositories : repo.name]
}

output "repository_registry_ids" {
  description = "Map of repository names to their registry IDs"
  value = {
    for i, repo in aws_ecr_repository.repositories :
    var.repository_names[i] => repo.registry_id
  }
}

# ==============================================================================
# CONVENIENCE OUTPUTS FOR SINGLE REPOSITORY SETUPS
# ==============================================================================

output "backend_repository_url" {
  description = "URL of the backend repository (for CI/CD integration)"
  value       = length(aws_ecr_repository.repositories) > 0 ? aws_ecr_repository.repositories[0].repository_url : null
}

output "backend_repository_arn" {
  description = "ARN of the backend repository (for IAM policies)"
  value       = length(aws_ecr_repository.repositories) > 0 ? aws_ecr_repository.repositories[0].arn : null
}

output "backend_repository_name" {
  description = "Name of the backend repository"
  value       = length(aws_ecr_repository.repositories) > 0 ? aws_ecr_repository.repositories[0].name : null
}

# ==============================================================================
# DOCKER COMMANDS FOR CI/CD
# ==============================================================================

output "docker_commands" {
  description = "Useful Docker commands for CI/CD pipelines"
  value = {
    for i, repo in aws_ecr_repository.repositories :
    var.repository_names[i] => {
      # AWS CLI login command
      login = "aws ecr get-login-password --region ${data.aws_region.current.name} | docker login --username AWS --password-stdin ${repo.repository_url}"

      # Docker build and tag command  
      build_and_tag = "docker build -t ${repo.repository_url}:latest ."

      # Docker push command
      push = "docker push ${repo.repository_url}:latest"

      # Complete CI/CD workflow
      full_workflow = [
        "aws ecr get-login-password --region ${data.aws_region.current.name} | docker login --username AWS --password-stdin ${repo.repository_url}",
        "docker build -t ${repo.repository_url}:latest .",
        "docker push ${repo.repository_url}:latest"
      ]
    }
  }
}

# ==============================================================================
# CONFIGURATION SUMMARY
# ==============================================================================

output "ecr_summary" {
  description = "Summary of ECR configuration"
  value = {
    # Basic configuration
    environment      = var.environment_name
    repository_count = length(aws_ecr_repository.repositories)
    repositories = {
      for i, repo in aws_ecr_repository.repositories :
      var.repository_names[i] => {
        name        = repo.name
        url         = repo.repository_url
        arn         = repo.arn
        registry_id = repo.registry_id
      }
    }

    # Configuration settings
    image_tag_mutability    = var.image_tag_mutability
    scan_on_push            = var.scan_on_push
    max_image_count         = var.max_image_count
    max_untagged_days       = var.max_untagged_image_days
    production_tag_patterns = var.production_tag_prefixes
    force_delete_enabled    = var.enable_force_delete

    # Metadata
    created_by     = "terraform"
    module_version = "1.0"
  }
}

# ==============================================================================
# DATA SOURCES FOR OUTPUTS
# ==============================================================================

# Get current AWS region for docker commands
data "aws_region" "current" {}
