terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0"
    }
  }
}

resource "aws_security_group" "alb" {
  count = var.security_group_type == "alb" ? 1 : 0

  name        = "${var.project_name}-alb-${var.region}"
  description = "Security group for Application Load Balancer"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }
}

resource "aws_security_group" "ec2" {
  count = var.security_group_type == "ec2" ? 1 : 0

  name        = "${var.project_name}-ec2-${var.region}"
  description = "Security group for EC2 instances"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = var.source_security_group_ids
    description     = "HTTP from ALB"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }
}

resource "aws_security_group" "rds" {
  count = var.security_group_type == "rds" ? 1 : 0

  name        = "${var.project_name}-rds-${var.region}"
  description = "Security group for RDS database"
  vpc_id      = var.vpc_id

  # Allow MySQL/MariaDB access from specified CIDR blocks
  dynamic "ingress" {
    for_each = var.allowed_cidr_blocks
    content {
      from_port   = 3306
      to_port     = 3306
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
      description = "MySQL/MariaDB from ${ingress.value}"
    }
  }

  # Allow MySQL/MariaDB access from source security groups
  dynamic "ingress" {
    for_each = var.source_security_group_ids
    content {
      from_port       = 3306
      to_port         = 3306
      protocol        = "tcp"
      security_groups = [ingress.value]
      description     = "MySQL/MariaDB from security group"
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }
}

resource "aws_iam_role" "ec2_role" {
  count = var.security_group_type == "ec2" ? 1 : 0
  name  = "${var.project_name}-ec2-role-${var.region}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "ec2_policies" {
  count = var.security_group_type == "ec2" ? 1 : 0
  name  = "${var.project_name}-ec2-policies-${var.region}"
  role  = aws_iam_role.ec2_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.s3_bucket_name}",
          "arn:aws:s3:::${var.s3_bucket_name}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters"
        ]
        Resource = [
          "arn:aws:ssm:${var.region}:*:parameter${var.parameter_store_prefix}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
          "ec2:DescribeVolumes",
          "ec2:DescribeTags"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
          "ec2:DescribeVolumes",
          "ec2:DescribeTags"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_profile" {
  count = var.security_group_type == "ec2" ? 1 : 0
  name  = "${var.project_name}-ec2-profile-${var.region}"
  role  = aws_iam_role.ec2_role[0].name
}

# Attach SSM Managed Instance Core policy to EC2 role
resource "aws_iam_role_policy_attachment" "ec2_ssm_managed_instance_core" {
  count      = var.security_group_type == "ec2" ? 1 : 0
  role       = aws_iam_role.ec2_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
