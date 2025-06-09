# modules/iam/main.tf
# Creates OIDC provider and IAM roles for GitHub Actions

# ==============================================================================
# DATA SOURCES
# ==============================================================================

# Try to get existing OIDC provider first
data "aws_iam_openid_connect_provider" "github" {
  count = var.create_oidc_provider ? 0 : 1
  url   = "https://token.actions.githubusercontent.com"
}

# Get information about the current AWS account and caller
data "aws_caller_identity" "current" {}

# ==============================================================================
# GITHUB OIDC PROVIDER
# ==============================================================================

# Create the OIDC identity provider for GitHub Actions (only if it doesn't exist)
resource "aws_iam_openid_connect_provider" "github" {
  count = var.create_oidc_provider ? 1 : 0

  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com",
  ]

  # GitHub's OIDC thumbprint - this is a fixed value
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd"
  ]

  tags = merge(var.common_tags, {
    Name        = "${var.name_prefix}-github-oidc"
    Purpose     = "github-actions-auth"
    Description = "OIDC provider for GitHub Actions authentication"
  })
}

# Local value to get the OIDC provider ARN (either created or existing)
locals {
  oidc_provider_arn = var.create_oidc_provider ? aws_iam_openid_connect_provider.github[0].arn : data.aws_iam_openid_connect_provider.github[0].arn
}

# ==============================================================================
# IAM POLICIES
# ==============================================================================

# Policy for ECR operations (push/pull images)
resource "aws_iam_policy" "github_ecr_policy" {
  name        = "${var.name_prefix}-github-ecr-policy"
  description = "Allows GitHub Actions to push/pull ECR images"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:DescribeRepositories",
          "ecr:DescribeImages",
          "ecr:ListImages",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
        Resource = var.ecr_repository_arn
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name        = "${var.name_prefix}-github-ecr-policy"
    Purpose     = "ecr-access"
    Description = "ECR access policy for GitHub Actions"
  })
}

# Policy for ECS operations (deploy services)
resource "aws_iam_policy" "github_ecs_policy" {
  name        = "${var.name_prefix}-github-ecs-policy"
  description = "Allows GitHub Actions to deploy ECS services"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecs:UpdateService",
          "ecs:DescribeServices",
          "ecs:DescribeClusters",
          "ecs:DescribeTaskDefinition",
          "ecs:RegisterTaskDefinition",
          "ecs:ListTasks",
          "ecs:DescribeTasks"
        ]
        Resource = [
          "arn:aws:ecs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:cluster/${var.name_prefix}-*",
          "arn:aws:ecs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:service/${var.name_prefix}-*/*",
          "arn:aws:ecs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:task-definition/${var.name_prefix}-*:*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ]
        Resource = [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.name_prefix}-ecs-*"
        ]
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name        = "${var.name_prefix}-github-ecs-policy"
    Purpose     = "ecs-deployment"
    Description = "ECS deployment policy for GitHub Actions"
  })
}

# Policy for S3 access (for integration tests that need model access)
resource "aws_iam_policy" "github_s3_policy" {
  name        = "${var.name_prefix}-github-s3-policy"
  description = "Allows GitHub Actions to access S3 models bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          var.models_bucket_arn,
          "${var.models_bucket_arn}/*"
        ]
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name        = "${var.name_prefix}-github-s3-policy"
    Purpose     = "s3-access"
    Description = "S3 access policy for GitHub Actions"
  })
}

# ==============================================================================
# IAM ROLES FOR GITHUB ACTIONS
# ==============================================================================

# Main deployment role for GitHub Actions
resource "aws_iam_role" "github_actions_role" {
  name = "${var.name_prefix}-github-actions-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = local.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}/${var.github_repo}:*"
          }
        }
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name        = "${var.name_prefix}-github-actions-role"
    Purpose     = "github-actions-deployment"
    Description = "Main role for GitHub Actions deployments"
  })
}

# Attach policies to the main deployment role
resource "aws_iam_role_policy_attachment" "github_ecr_attachment" {
  role       = aws_iam_role.github_actions_role.name
  policy_arn = aws_iam_policy.github_ecr_policy.arn
}

resource "aws_iam_role_policy_attachment" "github_ecs_attachment" {
  role       = aws_iam_role.github_actions_role.name
  policy_arn = aws_iam_policy.github_ecs_policy.arn
}

resource "aws_iam_role_policy_attachment" "github_s3_attachment" {
  role       = aws_iam_role.github_actions_role.name
  policy_arn = aws_iam_policy.github_s3_policy.arn
}

# Read-only role for pull requests and testing
resource "aws_iam_role" "github_actions_readonly_role" {
  name = "${var.name_prefix}-github-actions-readonly-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = local.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}/${var.github_repo}:*"
          }
        }
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name        = "${var.name_prefix}-github-actions-readonly-role"
    Purpose     = "github-actions-testing"
    Description = "Read-only role for GitHub Actions testing"
  })
}

# Attach read-only S3 policy for integration tests
resource "aws_iam_role_policy_attachment" "github_readonly_s3_attachment" {
  role       = aws_iam_role.github_actions_readonly_role.name
  policy_arn = aws_iam_policy.github_s3_policy.arn
}
