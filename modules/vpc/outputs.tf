# Outputs from the VPC module that other modules can reference

# ==============================================================================
# VPC INFORMATION
# ==============================================================================

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_arn" {
  description = "ARN of the VPC"
  value       = aws_vpc.main.arn
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

# ==============================================================================
# SUBNET INFORMATION
# ==============================================================================

output "public_subnet_ids" {
  description = "List of IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "List of IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "public_subnet_arns" {
  description = "List of ARNs of the public subnets"
  value       = aws_subnet.public[*].arn
}

output "private_subnet_arns" {
  description = "List of ARNs of the private subnets"
  value       = aws_subnet.private[*].arn
}

output "public_subnet_cidr_blocks" {
  description = "List of CIDR blocks of the public subnets"
  value       = aws_subnet.public[*].cidr_block
}

output "private_subnet_cidr_blocks" {
  description = "List of CIDR blocks of the private subnets"
  value       = aws_subnet.private[*].cidr_block
}

# ==============================================================================
# SECURITY GROUP INFORMATION
# ==============================================================================

output "ecs_tasks_security_group_id" {
  description = "ID of the security group for ECS tasks"
  value       = aws_security_group.ecs_tasks.id
}

output "load_balancer_security_group_id" {
  description = "ID of the security group for load balancer"
  value       = aws_security_group.load_balancer.id
}

# ==============================================================================
# GATEWAY INFORMATION
# ==============================================================================

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

output "nat_gateway_ids" {
  description = "List of IDs of the NAT Gateways"
  value       = aws_nat_gateway.main[*].id
}

output "nat_public_ips" {
  description = "List of public Elastic IP addresses associated with NAT Gateways"
  value       = aws_eip.nat[*].public_ip
}

# ==============================================================================
# ROUTE TABLE INFORMATION
# ==============================================================================

output "public_route_table_id" {
  description = "ID of the public route table"
  value       = aws_route_table.public.id
}

output "private_route_table_ids" {
  description = "List of IDs of the private route tables"
  value       = aws_route_table.private[*].id
}

# ==============================================================================
# AVAILABILITY ZONE INFORMATION
# ==============================================================================

output "availability_zones" {
  description = "List of availability zones used by subnets"
  value       = local.azs
}

output "azs_count" {
  description = "Number of availability zones used"
  value       = length(local.azs)
}

# ==============================================================================
# CONFIGURATION SUMMARY
# ==============================================================================

output "vpc_summary" {
  description = "Summary of VPC configuration"
  value = {
    # Basic VPC info
    vpc_id      = aws_vpc.main.id
    vpc_cidr    = aws_vpc.main.cidr_block
    environment = var.environment_name
    region      = var.aws_region

    # Subnet configuration
    availability_zones = local.azs
    public_subnets = {
      count = local.public_subnet_count
      ids   = aws_subnet.public[*].id
      cidrs = aws_subnet.public[*].cidr_block
    }
    private_subnets = {
      count = local.private_subnet_count
      ids   = aws_subnet.private[*].id
      cidrs = aws_subnet.private[*].cidr_block
    }

    # Network features
    nat_gateway_enabled = var.enable_nat_gateway
    single_nat_gateway  = var.single_nat_gateway
    nat_public_ips      = var.enable_nat_gateway ? aws_eip.nat[*].public_ip : []

    # Security groups
    security_groups = {
      ecs_tasks     = aws_security_group.ecs_tasks.id
      load_balancer = aws_security_group.load_balancer.id
    }

    # Metadata
    created_by     = "terraform"
    module_version = "1.0"
  }
}

# ==============================================================================
# CONVENIENCE OUTPUTS FOR ECS MODULE
# ==============================================================================

output "ecs_subnet_ids" {
  description = "Subnet IDs where ECS tasks should be deployed (private subnets)"
  value       = aws_subnet.private[*].id
}

output "alb_subnet_ids" {
  description = "Subnet IDs where Application Load Balancer should be deployed (public subnets)"
  value       = aws_subnet.public[*].id
}
