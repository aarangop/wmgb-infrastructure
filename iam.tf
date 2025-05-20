# Add to your infrastructure/main.tf or create a new iam.tf file

resource "aws_iam_group" "whos_my_good_boy_developers" {
  name = "WhosMyGoodBoyDeveloper"
}

# Create policy for S3 access
resource "aws_iam_policy" "model_access_policy" {
  name        = "wmgb-model-developer-access-policy"
  description = "Policy to access ML models in S3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Account level permissions
        Effect = "Allow",
        Action = [
          "s3:ListAllMyBuckets"
        ],
        Resource = "*"
      },
      {
        Action = [
          "s3:GetObject",
          "s3:ListBucket",
          "s3:PutObject",
          "s3:HeadObject"
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:s3:::whos-my-good-boy-models",
          "arn:aws:s3:::whos-my-good-boy-models/*"
        ]
      }
    ]
  })

  tags = {
    Project = "WhosMyGoodBoy"
  }
}

resource "aws_iam_policy" "ecs_s3_model_access_policy" {
  name        = "ecs-model-access-policy"
  description = "Policy to access ML models in S3"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:GetObject",
        "s3:HeadObject",
        "s3:ListBucket"
      ]
      Resource = [
        "arn:aws:s3:::whos-my-good-boy-models",
        "arn:aws:s3:::whos-my-good-boy-models/*"
      ]
    }]
  })
  tags = {
    Project = "WhosMyGoodBoy"
  }
}

# Attach this policy to the group
resource "aws_iam_group_policy_attachment" "developer_s3_access" {
  group      = aws_iam_group.whos_my_good_boy_developers.name
  policy_arn = aws_iam_policy.model_access_policy.arn
}

# Roles and policies for ECS
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "wmgb-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Project = "WhosMyGoodBoy"
  }
}

# Attach the Amazon managed policy for ECS task execution
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Task role - allows the container to access AWS services
resource "aws_iam_role" "ecs_task_role" {
  name = "wmgb-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Project = "WhosMyGoodBoy"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_s3_access" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.ecs_s3_model_access_policy.arn
}
