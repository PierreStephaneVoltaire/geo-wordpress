terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0"
    }
  }
}

# Data sources
data "aws_availability_zones" "available" {
  region = var.region_config.region
  state  = "available"
}

# VPC
resource "aws_vpc" "main" {
  region               = var.region_config.region
  cidr_block           = var.region_config.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, {
    Name = "${var.project_name}-vpc-${var.region_name}-${var.random_suffix}"
  })
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  region = var.region_config.region
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "${var.project_name}-igw-${var.region_name}-${var.random_suffix}"
  })
}

# Public Subnets (for ALB)
resource "aws_subnet" "public" {
  count = min(length(data.aws_availability_zones.available.names), 3)

  region                  = var.region_config.region
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.region_config.vpc_cidr, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = "${var.project_name}-public-${count.index + 1}-${var.region_name}-${var.random_suffix}"
    Type = "Public"
  })
}

# Private Subnets (for ECS Fargate, RDS, ElastiCache)
resource "aws_subnet" "private" {
  count = min(length(data.aws_availability_zones.available.names), 3)

  region            = var.region_config.region
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.region_config.vpc_cidr, 8, count.index + 10)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(var.tags, {
    Name = "${var.project_name}-private-${count.index + 1}-${var.region_name}-${var.random_suffix}"
    Type = "Private"
  })
}

# Database Subnets
resource "aws_subnet" "database" {
  count = min(length(data.aws_availability_zones.available.names), 3)

  region            = var.region_config.region
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.region_config.vpc_cidr, 8, count.index + 20)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(var.tags, {
    Name = "${var.project_name}-db-${count.index + 1}-${var.region_name}-${var.random_suffix}"
    Type = "Database"
  })
}

# NAT Gateway Elastic IPs
resource "aws_eip" "nat" {
  count = length(aws_subnet.public)

  region = var.region_config.region
  domain = "vpc"

  tags = merge(var.tags, {
    Name = "${var.project_name}-nat-eip-${count.index + 1}-${var.region_name}-${var.random_suffix}"
  })

  depends_on = [aws_internet_gateway.main]
}

# NAT Gateways
resource "aws_nat_gateway" "main" {
  count = length(aws_subnet.public)

  region        = var.region_config.region
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(var.tags, {
    Name = "${var.project_name}-nat-${count.index + 1}-${var.region_name}-${var.random_suffix}"
  })

  depends_on = [aws_internet_gateway.main]
}

# Public Route Table
resource "aws_route_table" "public" {
  region = var.region_config.region
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-public-rt-${var.region_name}-${var.random_suffix}"
  })
}

# Private Route Tables (one per AZ for high availability)
resource "aws_route_table" "private" {
  count = length(aws_subnet.private)

  region = var.region_config.region
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-private-rt-${count.index + 1}-${var.region_name}-${var.random_suffix}"
  })
}

# Database Route Table
resource "aws_route_table" "database" {
  region = var.region_config.region
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "${var.project_name}-db-rt-${var.region_name}-${var.random_suffix}"
  })
}

# Route Table Associations - Public
resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  region         = var.region_config.region
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Route Table Associations - Private
resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private)

  region         = var.region_config.region
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# Route Table Associations - Database
resource "aws_route_table_association" "database" {
  count = length(aws_subnet.database)

  region         = var.region_config.region
  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database.id
}

# Security Groups

# ALB Security Group
resource "aws_security_group" "alb" {
  region      = var.region_config.region
  name_prefix = "${var.project_name}-alb-${var.region_name}-"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-alb-sg-${var.region_name}-${var.random_suffix}"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# ECS Security Group
resource "aws_security_group" "ecs" {
  region      = var.region_config.region
  name_prefix = "${var.project_name}-ecs-${var.region_name}-"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-ecs-sg-${var.region_name}-${var.random_suffix}"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# RDS Security Group
resource "aws_security_group" "rds" {
  region      = var.region_config.region
  name_prefix = "${var.project_name}-rds-${var.region_name}-"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "MySQL/Aurora from ECS"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-rds-sg-${var.region_name}-${var.random_suffix}"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# ElastiCache Security Group
resource "aws_security_group" "redis" {
  region      = var.region_config.region
  name_prefix = "${var.project_name}-redis-${var.region_name}-"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Redis from ECS"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-redis-sg-${var.region_name}-${var.random_suffix}"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# DB Subnet Group
resource "aws_db_subnet_group" "main" {
  region     = var.region_config.region
  name       = "${var.project_name}-db-subnet-${var.region_name}-${var.random_suffix}"
  subnet_ids = aws_subnet.database[*].id

  tags = merge(var.tags, {
    Name = "${var.project_name}-db-subnet-group-${var.region_name}-${var.random_suffix}"
  })
}

# ElastiCache Subnet Group
resource "aws_elasticache_subnet_group" "main" {
  region     = var.region_config.region
  name       = "${var.project_name}-redis-subnet-${var.region_name}-${var.random_suffix}"
  subnet_ids = aws_subnet.private[*].id

  tags = var.tags
}