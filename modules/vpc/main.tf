# modules/vpc/main.tf
# Creates VPC networking infrastructure for containerized applications

# ==============================================================================
# DATA SOURCES
# ==============================================================================

# Get available availability zones for the current region
# This ensures we use AZs that actually exist and are available
data "aws_availability_zones" "available" {
  state = "available"
}

# ==============================================================================
# LOCAL VALUES
# ==============================================================================

locals {
  # Use provided AZs or auto-detect from region
  # Take only the first 2 AZs to keep costs manageable
  azs = length(var.availability_zones) > 0 ? var.availability_zones : slice(data.aws_availability_zones.available.names, 0, 2)

  # Calculate how many subnets we're actually creating
  public_subnet_count  = min(length(var.public_subnet_cidrs), length(local.azs))
  private_subnet_count = min(length(var.private_subnet_cidrs), length(local.azs))

  # VPC name
  vpc_name = "${var.name_prefix}-vpc"
}

# ==============================================================================
# VPC
# ==============================================================================

# Main VPC - the virtual network that contains all our resources
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  tags = merge(var.common_tags, {
    Name        = local.vpc_name
    Purpose     = "main-network"
    Description = "VPC for ${var.environment_name} environment"
  })
}

# ==============================================================================
# INTERNET GATEWAY
# ==============================================================================

# Internet Gateway - provides internet access to public subnets
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.common_tags, {
    Name        = "${var.name_prefix}-igw"
    Purpose     = "internet-access"
    Description = "Internet gateway for public subnets"
  })
}

# ==============================================================================
# PUBLIC SUBNETS
# ==============================================================================

# Public subnets - for resources that need direct internet access
# These will host load balancers and potentially bastion hosts
resource "aws_subnet" "public" {
  count = local.public_subnet_count

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = true

  tags = merge(var.common_tags, {
    Name        = "${var.name_prefix}-public-${local.azs[count.index]}"
    Type        = "public"
    AZ          = local.azs[count.index]
    Purpose     = "public-resources"
    Description = "Public subnet for load balancers and internet-facing resources"
  })
}

# Public route table - directs traffic to internet gateway
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  # Route all traffic (0.0.0.0/0) to the internet gateway
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(var.common_tags, {
    Name        = "${var.name_prefix}-public-rt"
    Type        = "public"
    Purpose     = "internet-routing"
    Description = "Route table for public subnets"
  })
}

# Associate public subnets with the public route table
resource "aws_route_table_association" "public" {
  count = local.public_subnet_count

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ==============================================================================
# PRIVATE SUBNETS
# ==============================================================================

# Private subnets - for application servers and databases
# These subnets don't have direct internet access for security
resource "aws_subnet" "private" {
  count = local.private_subnet_count

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = local.azs[count.index]

  tags = merge(var.common_tags, {
    Name        = "${var.name_prefix}-private-${local.azs[count.index]}"
    Type        = "private"
    AZ          = local.azs[count.index]
    Purpose     = "application-servers"
    Description = "Private subnet for ECS tasks and databases"
  })
}

# ==============================================================================
# NAT GATEWAY (CONDITIONAL)
# ==============================================================================

# Elastic IPs for NAT Gateway(s)
# NAT Gateway needs a static IP to provide consistent outbound internet access
resource "aws_eip" "nat" {
  count = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : local.private_subnet_count) : 0

  domain     = "vpc"
  depends_on = [aws_internet_gateway.main]

  tags = merge(var.common_tags, {
    Name        = "${var.name_prefix}-nat-eip-${count.index + 1}"
    Purpose     = "nat-gateway"
    Description = "Elastic IP for NAT Gateway"
  })
}

# NAT Gateway - provides outbound internet access for private subnets
# This allows private resources to download updates, packages, etc.
resource "aws_nat_gateway" "main" {
  count = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : local.private_subnet_count) : 0

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  depends_on = [aws_internet_gateway.main]

  tags = merge(var.common_tags, {
    Name        = "${var.name_prefix}-nat-${count.index + 1}"
    Purpose     = "private-internet-access"
    Description = "NAT Gateway for private subnet outbound traffic"
  })
}

# Private route tables - one per AZ for high availability
resource "aws_route_table" "private" {
  count = local.private_subnet_count

  vpc_id = aws_vpc.main.id

  # Route to NAT Gateway if enabled, otherwise no internet access
  dynamic "route" {
    for_each = var.enable_nat_gateway ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = var.single_nat_gateway ? aws_nat_gateway.main[0].id : aws_nat_gateway.main[count.index].id
    }
  }

  tags = merge(var.common_tags, {
    Name        = "${var.name_prefix}-private-rt-${local.azs[count.index]}"
    Type        = "private"
    AZ          = local.azs[count.index]
    Purpose     = "private-routing"
    Description = "Route table for private subnet in ${local.azs[count.index]}"
  })
}

# Associate private subnets with their respective route tables
resource "aws_route_table_association" "private" {
  count = local.private_subnet_count

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# ==============================================================================
# SECURITY GROUPS
# ==============================================================================

# Default security group for ECS tasks
# This provides a baseline security configuration
resource "aws_security_group" "ecs_tasks" {
  name_prefix = "${var.name_prefix}-ecs-tasks"
  vpc_id      = aws_vpc.main.id
  description = "Security group for ECS tasks"

  # Inbound rules
  ingress {
    description = "HTTP from load balancer"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr] # Only from within VPC
  }

  ingress {
    description = "HTTPS from load balancer"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr] # Only from within VPC
  }

  ingress {
    description = "Custom app port"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr] # FastAPI default port
  }

  # Outbound rules - allow all outbound traffic
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name        = "${var.name_prefix}-ecs-tasks-sg"
    Purpose     = "ecs-security"
    Description = "Security group for ECS tasks"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Load balancer security group
# This will be used by ALB in the ECS module
resource "aws_security_group" "load_balancer" {
  name_prefix = "${var.name_prefix}-alb"
  vpc_id      = aws_vpc.main.id
  description = "Security group for Application Load Balancer"

  # Allow HTTP from internet
  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTPS from internet
  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound to VPC
  egress {
    description = "All outbound to VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = merge(var.common_tags, {
    Name        = "${var.name_prefix}-alb-sg"
    Purpose     = "load-balancer-security"
    Description = "Security group for Application Load Balancer"
  })

  lifecycle {
    create_before_destroy = true
  }
}
