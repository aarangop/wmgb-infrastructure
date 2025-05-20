# ecs.tf
resource "aws_ecs_cluster" "main" {
  name = "wmgb-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Project = "WhosMyGoodBoy"
  }
}

resource "aws_ecs_task_definition" "backend" {
  family                   = "wmgb-backend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "wmgb-backend"
      image     = "${aws_ecr_repository.backend_repo.repository_url}:latest"
      essential = true
      portMappings = [
        {
          containerPort = 8000
          hostPort      = 8000
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/wmgb-backend"
          "awslogs-region"        = "us-east-2" # Update to match your region
          "awslogs-stream-prefix" = "ecs"
          "awslogs-create-group"  = "true"
        }
      }
      environment = [
        {
          name  = "API_VERSION"
          value = "v1"
        },
        {
          name  = "AWS_REGION"
          value = "us-east-2"
        },
        {
          name  = "MODELS_DIR"
          value = "/app/ml_models"
        },
        {
          name  = "S3_MODELS_BUCKET"
          value = "whos-my-good-boy-models"
        },
        {
          name  = "LOG_LEVEL"
          value = "INFO"
        },
        {
          name  = "PORT"
          value = "8000"
        },
        {
          name  = "USE_LOCAL_MODEL_REPO"
          value = "false"
        },
        {
          name  = "MODEL_REPOSITORY_TYPE"
          value = "caching"
        },
        {
          name  = "CAT_DOG_OTHER_CLASSIFIER"
          value = "cat-dog-other-classifier"
        }
      ]
    }
  ])

  tags = {
    Project = "WhosMyGoodBoy"
  }
}

resource "aws_cloudwatch_log_group" "backend" {
  name              = "/ecs/wmgb-backend"
  retention_in_days = 14

  tags = {
    Project = "WhosMyGoodBoy"
  }
}
