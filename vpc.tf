# network.tf
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name    = "wmgb-vpc"
    Project = "WhosMyGoodBoy"
  }
}

# Create two public subnets in different availability zones
resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-2a" # Update to match your region
  map_public_ip_on_launch = true

  tags = {
    Name    = "wmgb-public-subnet-1"
    Project = "WhosMyGoodBoy"
  }
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-2b" # Update to match your region
  map_public_ip_on_launch = true

  tags = {
    Name    = "wmgb-public-subnet-2"
    Project = "WhosMyGoodBoy"
  }
}

# Create internet gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name    = "wmgb-igw"
    Project = "WhosMyGoodBoy"
  }
}

# Create route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name    = "wmgb-public-rt"
    Project = "WhosMyGoodBoy"
  }
}

# Associate route tables with subnets
resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

# Security group for the load balancer
resource "aws_security_group" "lb_sg" {
  name        = "wmgb-lb-sg"
  description = "Security group for the load balancer"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "wmgb-lb-sg"
    Project = "WhosMyGoodBoy"
  }
}

# Security group for ECS tasks
resource "aws_security_group" "ecs_tasks_sg" {
  name        = "wmgb-ecs-tasks-sg"
  description = "Security group for ECS tasks"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Allow traffic from ALB"
    from_port       = 8000 # FastAPI port
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.lb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "wmgb-ecs-tasks-sg"
    Project = "WhosMyGoodBoy"
  }
}
