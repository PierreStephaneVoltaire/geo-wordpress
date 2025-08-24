# Test EC2 instances for WordPress with Ansible
data "aws_region" "current" {}

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Security group for test instances
resource "aws_security_group" "test_wordpress" {
  name        = "test-wordpress-sg"
  description = "Security group for test WordPress instances"
  vpc_id      = module.singapore_network.vpc_id

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

  tags = {
    Name = "test-wordpress-sg"
  }
}

# IAM role for test instances
resource "aws_iam_role" "test_wordpress_role" {
  name = "test-wordpress-role"

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

resource "aws_iam_role_policy" "test_wordpress_policy" {
  name = "test-wordpress-policy"
  role = aws_iam_role.test_wordpress_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = [
          "arn:aws:ssm:*:*:parameter/${var.project_name}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          module.data.s3_bucket_arn,
          "${module.data.s3_bucket_arn}/*"
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
      }
    ]
  })
}

# Attach the AWS managed policy for SSM Session Manager
resource "aws_iam_role_policy_attachment" "test_wordpress_ssm" {
  role       = aws_iam_role.test_wordpress_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "test_wordpress_profile" {
  name = "test-wordpress-profile"
  role = aws_iam_role.test_wordpress_role.name
}

# Test instance in Singapore region
resource "aws_instance" "test_wordpress_singapore" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = "t3.micro"
  iam_instance_profile        = aws_iam_instance_profile.test_wordpress_profile.name
  vpc_security_group_ids      = [aws_security_group.test_wordpress.id]
  subnet_id                   = module.singapore_network.public_subnets[0]
  associate_public_ip_address = true

  user_data = templatefile("${path.module}/templates/wordpress_test_userdata.tpl", {
    region                    = data.aws_region.current.name
    db_region                 = "ap-southeast-1" # Singapore primary
    project_name              = var.project_name
    environment               = var.environment
    db_endpoint_param         = module.data.singapore_db_endpoint_param
    db_username_param         = module.data.singapore_db_username_param
    db_password_param         = module.data.singapore_db_password_param
    s3_bucket_param           = module.data.s3_bucket_param
    primary_db_endpoint_param = module.data.singapore_db_endpoint_param
    admin_email               = var.admin_email
  })

  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    encrypted   = true
  }

  tags = {
    Name        = "test-wordpress-singapore"
    Environment = "test"
  }
}

# Test instance in Ireland region (if deploying there)
resource "aws_instance" "test_wordpress_ireland" {
  count = var.create_ireland_test ? 1 : 0

  provider                    = aws.ireland
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = "t3.micro"
  iam_instance_profile        = aws_iam_instance_profile.test_wordpress_profile.name
  vpc_security_group_ids      = [aws_security_group.test_wordpress.id]
  subnet_id                   = module.ireland_network.public_subnets[0]
  associate_public_ip_address = true

  user_data = templatefile("${path.module}/templates/wordpress_test_userdata.tpl", {
    region                    = "eu-west-1"
    db_region                 = "eu-west-1" # Ireland replica
    project_name              = var.project_name
    environment               = var.environment
    db_endpoint_param         = module.data.ireland_db_endpoint_param
    db_username_param         = module.data.ireland_db_username_param
    db_password_param         = module.data.ireland_db_password_param
    s3_bucket_param           = module.data.s3_bucket_param
    primary_db_endpoint_param = module.data.singapore_db_endpoint_param
    admin_email               = var.admin_email
  })

  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    encrypted   = true
  }

  tags = {
    Name        = "test-wordpress-ireland"
    Environment = "test"
  }
}

# Variable to control Ireland instance creation
variable "create_ireland_test" {
  description = "Create test instance in Ireland"
  type        = bool
  default     = false
}

# Outputs
output "singapore_test_ip" {
  description = "Public IP of Singapore test instance"
  value       = aws_instance.test_wordpress_singapore.public_ip
}

output "singapore_test_url" {
  description = "WordPress URL for Singapore test instance"
  value       = "http://${aws_instance.test_wordpress_singapore.public_ip}"
}

output "ireland_test_ip" {
  description = "Public IP of Ireland test instance"
  value       = var.create_ireland_test ? aws_instance.test_wordpress_ireland[0].public_ip : "Not created"
}

output "ireland_test_url" {
  description = "WordPress URL for Ireland test instance"
  value       = var.create_ireland_test ? "http://${aws_instance.test_wordpress_ireland[0].public_ip}" : "Not created"
}
