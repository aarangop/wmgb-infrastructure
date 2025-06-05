# modules/ecs/outputs.tf
# Outputs from the ECS module

# ==============================================================================
# CLUSTER INFORMATION
# ==============================================================================

output "cluster_id" {
  description = "ID of the ECS cluster"
  value       = aws_ecs_cluster.main.id
}

output "cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = aws_ecs_cluster.main.arn
}

output "cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

# ==============================================================================
# SERVICE INFORMATION
# ==============================================================================

output "service_id" {
  description = "ID of the ECS service"
  value       = aws_ecs_service.main.id
}

output "service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.main.name
}

output "service_arn" {
  description = "ARN of the ECS service"
  value       = aws_ecs_service.main.id
}

output "task_definition_arn" {
  description = "ARN of the task definition"
  value       = aws_ecs_task_definition.main.arn
}

# ==============================================================================
# LOAD BALANCER INFORMATION
# ==============================================================================

output "load_balancer_dns_name" {
  description = "DNS name of the load balancer"
  value       = var.enable_load_balancer ? aws_lb.main[0].dns_name : null
}

output "load_balancer_arn" {
  description = "ARN of the load balancer"
  value       = var.enable_load_balancer ? aws_lb.main[0].arn : null
}

output "load_balancer_zone_id" {
  description = "Zone ID of the load balancer (for Route 53 records)"
  value       = var.enable_load_balancer ? aws_lb.main[0].zone_id : null
}

output "target_group_arn" {
  description = "ARN of the target group"
  value       = var.enable_load_balancer ? aws_lb_target_group.main[0].arn : null
}

# ==============================================================================
# APPLICATION ACCESS INFORMATION
# ==============================================================================

output "application_url" {
  description = "URL to access the application"
  value       = var.enable_load_balancer ? "http://${aws_lb.main[0].dns_name}" : null
}

output "health_check_url" {
  description = "URL for health check endpoint"
  value       = var.enable_load_balancer ? "http://${aws_lb.main[0].dns_name}${var.health_check_path}" : null
}

# ==============================================================================
# LOGGING INFORMATION
# ==============================================================================

output "log_group_name" {
  description = "CloudWatch log group name"
  value       = var.enable_logging ? aws_cloudwatch_log_group.ecs_logs[0].name : null
}

output "log_group_arn" {
  description = "CloudWatch log group ARN"
  value       = var.enable_logging ? aws_cloudwatch_log_group.ecs_logs[0].arn : null
}

# ==============================================================================
# IAM INFORMATION
# ==============================================================================

output "task_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  value       = aws_iam_role.ecs_task_execution_role.arn
}

output "task_role_arn" {
  description = "ARN of the ECS task role"
  value       = aws_iam_role.ecs_task_role.arn
}

# ==============================================================================
# MONITORING AND DEBUGGING
# ==============================================================================

output "aws_cli_commands" {
  description = "Useful AWS CLI commands for monitoring and debugging"
  value = {
    # View service status
    describe_service = "aws ecs describe-services --cluster ${aws_ecs_cluster.main.name} --services ${aws_ecs_service.main.name}"

    # View running tasks
    list_tasks = "aws ecs list-tasks --cluster ${aws_ecs_cluster.main.name} --service-name ${aws_ecs_service.main.name}"

    # View logs (if logging enabled)
    view_logs = var.enable_logging ? "aws logs tail ${aws_cloudwatch_log_group.ecs_logs[0].name} --follow" : "Logging not enabled"

    # Scale service
    scale_service = "aws ecs update-service --cluster ${aws_ecs_cluster.main.name} --service ${aws_ecs_service.main.name} --desired-count"

    # Force new deployment
    force_deployment = "aws ecs update-service --cluster ${aws_ecs_cluster.main.name} --service ${aws_ecs_service.main.name} --force-new-deployment"
  }
}

# ==============================================================================
# CONFIGURATION SUMMARY
# ==============================================================================

output "ecs_summary" {
  description = "Summary of ECS configuration"
  value = {
    # Basic information
    environment  = var.environment_name
    cluster_name = aws_ecs_cluster.main.name
    service_name = aws_ecs_service.main.name

    # Task configuration
    task_cpu       = var.task_cpu
    task_memory    = var.task_memory
    desired_count  = var.desired_count
    container_port = var.container_port

    # Container information
    ecr_repository = var.ecr_repository_url
    image_tag      = var.container_image_tag
    models_bucket  = var.models_bucket_name

    # Load balancer
    load_balancer_enabled = var.enable_load_balancer
    application_url       = var.enable_load_balancer ? "http://${aws_lb.main[0].dns_name}" : "No load balancer"

    # Logging
    logging_enabled = var.enable_logging
    log_group       = var.enable_logging ? aws_cloudwatch_log_group.ecs_logs[0].name : "Logging disabled"
    log_retention   = var.log_retention_days

    # Health monitoring
    health_check_path = var.health_check_path
    health_check_url  = var.enable_load_balancer ? "http://${aws_lb.main[0].dns_name}${var.health_check_path}" : "No load balancer"

    # Auto scaling
    auto_scaling_enabled = var.enable_auto_scaling

    # Metadata
    created_by     = "terraform"
    module_version = "1.0"
  }
}

# ==============================================================================
# CONVENIENCE OUTPUTS FOR DEVELOPMENT
# ==============================================================================

output "quick_access" {
  description = "Quick access information for development"
  value = {
    # Application access
    app_url = var.enable_load_balancer ? "http://${aws_lb.main[0].dns_name}" : "Load balancer not enabled"

    # AWS Console links (region-specific)
    ecs_console  = "https://${data.aws_region.current.name}.console.aws.amazon.com/ecs/home?region=${data.aws_region.current.name}#/clusters/${aws_ecs_cluster.main.name}/services"
    logs_console = var.enable_logging ? "https://${data.aws_region.current.name}.console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.name}#logsV2:log-groups/log-group/${replace(aws_cloudwatch_log_group.ecs_logs[0].name, "/", "$252F")}" : "Logging not enabled"
    lb_console   = var.enable_load_balancer ? "https://${data.aws_region.current.name}.console.aws.amazon.com/ec2/v2/home?region=${data.aws_region.current.name}#LoadBalancers:search=${aws_lb.main[0].name}" : "Load balancer not enabled"

    # Local development
    local_port_forward = "kubectl port-forward svc/${var.service_name} 8000:${var.container_port}" # If using kubectl
    docker_run_local   = "docker run -p 8000:${var.container_port} ${var.ecr_repository_url}:${var.container_image_tag}"
  }
}
