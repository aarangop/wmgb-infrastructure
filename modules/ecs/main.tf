# modules/ecs/main.tf
# Creates ECS cluster and services for running containerized applications

# ==============================================================================
# LOCAL VALUES
# ==============================================================================

locals {
  # Cluster name with fallback
  cluster_name = var.cluster_name != "" ? var.cluster_name : "${var.name_prefix}-cluster"

  # Service name
  service_name = "${var.name_prefix}-${var.service_name}"

  # Log group name
  log_group_name = "/ecs/${var.name_prefix}/${var.service_name}"

  # Load balancer name (ALB names have length limits)
  lb_name = "${var.name_prefix}-alb"
}

# ==============================================================================
# ECS CLUSTER
# ==============================================================================

# ECS cluster - logical grouping of tasks and services
resource "aws_ecs_cluster" "main" {
  name = local.cluster_name

  # Enable CloudWatch Container Insights for monitoring (optional)
  setting {
    name  = "containerInsights"
    value = var.environment_name == "prod" ? "enabled" : "disabled" # Cost optimization
  }

  tags = merge(var.common_tags, {
    Name        = local.cluster_name
    Purpose     = "container-orchestration"
    Description = "ECS cluster for ${var.environment_name} environment"
  })
}

# ==============================================================================
# CLOUDWATCH LOG GROUP
# ==============================================================================

# CloudWatch log group for container logs
resource "aws_cloudwatch_log_group" "ecs_logs" {
  count = var.enable_logging ? 1 : 0

  name              = local.log_group_name
  retention_in_days = var.log_retention_days

  tags = merge(var.common_tags, {
    Name        = local.log_group_name
    Purpose     = "container-logging"
    Description = "Logs for ${var.service_name} service"
  })
}

# ==============================================================================
# IAM ROLES FOR ECS TASKS
# ==============================================================================

# Task execution role - required for ECS to pull images and write logs
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.name_prefix}-ecs-task-execution-role"

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

  tags = merge(var.common_tags, {
    Name        = "${var.name_prefix}-ecs-task-execution-role"
    Purpose     = "ecs-task-execution"
    Description = "Allows ECS tasks to pull images and write logs"
  })
}

# Attach AWS managed policy for ECS task execution
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Task role - for the application running inside the container
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.name_prefix}-ecs-task-role"

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

  tags = merge(var.common_tags, {
    Name        = "${var.name_prefix}-ecs-task-role"
    Purpose     = "ecs-task-application"
    Description = "Role for application running inside ECS tasks"
  })
}

# Basic S3 access policy for the models bucket
resource "aws_iam_role_policy" "ecs_task_s3_access" {
  name = "${var.name_prefix}-ecs-s3-access"
  role = aws_iam_role.ecs_task_role.id

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
          "arn:aws:s3:::${var.models_bucket_name}",
          "arn:aws:s3:::${var.models_bucket_name}/*"
        ]
      }
    ]
  })
}

# ==============================================================================
# ECS TASK DEFINITION
# ==============================================================================

# Task definition - blueprint for running containers
resource "aws_ecs_task_definition" "main" {
  family                   = local.service_name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  # Container definition
  container_definitions = jsonencode([
    {
      name  = var.service_name
      image = "${var.ecr_repository_url}:${var.container_image_tag}"

      # Port configuration
      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
        }
      ]

      # Environment variables
      environment = [
        for key, value in merge(
          var.environment_variables,
          {
            # Default environment variables
            ENVIRONMENT   = var.environment_name
            MODELS_BUCKET = var.models_bucket_name
            PORT          = tostring(var.container_port)
          }
          ) : {
          name  = key
          value = value
        }
      ]

      # Secrets (if any)
      secrets = [
        for key, value in var.secrets : {
          name      = key
          valueFrom = value
        }
      ]

      # Logging configuration
      logConfiguration = var.enable_logging ? {
        logDriver = "awslogs"
        options = {
          awslogs-group         = local.log_group_name
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = "ecs"
        }
      } : null

      # Health check
      healthCheck = {
        command = [
          "CMD-SHELL",
          "curl -f http://localhost:${var.container_port}${var.health_check_path} || exit 1"
        ]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }

      # Resource requirements
      essential = true
    }
  ])

  tags = merge(var.common_tags, {
    Name        = local.service_name
    Purpose     = "task-definition"
    Description = "Task definition for ${var.service_name}"
  })
}

# ==============================================================================
# APPLICATION LOAD BALANCER
# ==============================================================================

# Application Load Balancer for internet-facing traffic
resource "aws_lb" "main" {
  count = var.enable_load_balancer ? 1 : 0

  name               = local.lb_name
  internal           = false # Internet-facing
  load_balancer_type = var.load_balancer_type
  security_groups    = [var.alb_security_group_id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = var.enable_deletion_protection

  tags = merge(var.common_tags, {
    Name        = local.lb_name
    Purpose     = "load-balancer"
    Description = "Application Load Balancer for ${var.service_name}"
  })
}

# Target group for the ECS service
resource "aws_lb_target_group" "main" {
  count = var.enable_load_balancer ? 1 : 0

  name        = "${var.name_prefix}-tg"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip" # Required for Fargate

  # Health check configuration
  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = var.health_check_path
    matcher             = "200"
    port                = "traffic-port"
    protocol            = "HTTP"
  }

  tags = merge(var.common_tags, {
    Name        = "${var.name_prefix}-tg"
    Purpose     = "load-balancer-target"
    Description = "Target group for ${var.service_name}"
  })
}

# Load balancer listener
resource "aws_lb_listener" "main" {
  count = var.enable_load_balancer ? 1 : 0

  load_balancer_arn = aws_lb.main[0].arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main[0].arn
  }

  tags = merge(var.common_tags, {
    Name        = "${var.name_prefix}-listener"
    Purpose     = "load-balancer-listener"
    Description = "HTTP listener for ${var.service_name}"
  })
}

# ==============================================================================
# ECS SERVICE
# ==============================================================================

# ECS service - manages running tasks and integrates with load balancer
resource "aws_ecs_service" "main" {
  name            = local.service_name
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.main.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  # Network configuration
  network_configuration {
    security_groups  = [var.ecs_security_group_id]
    subnets          = var.private_subnet_ids
    assign_public_ip = false # Private subnets, no public IP needed
  }

  # Load balancer integration
  dynamic "load_balancer" {
    for_each = var.enable_load_balancer ? [1] : []
    content {
      target_group_arn = aws_lb_target_group.main[0].arn
      container_name   = var.service_name
      container_port   = var.container_port
    }
  }

  # Deployment configuration - correct syntax for Terraform AWS provider
  deployment_maximum_percent         = var.deployment_maximum_percent
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent

  # Wait for load balancer to be ready
  depends_on = [aws_lb_listener.main]

  tags = merge(var.common_tags, {
    Name        = local.service_name
    Purpose     = "ecs-service"
    Description = "ECS service for ${var.service_name}"
  })
}

# ==============================================================================
# DATA SOURCES
# ==============================================================================

# Get current AWS region
data "aws_region" "current" {}
