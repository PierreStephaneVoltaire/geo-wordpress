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
resource "random_password" "jenkins_admin_password" {
  length  = 16
  special = false
}

resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_ssm_parameter" "jenkins_admin_username" {
  name  = "/jenkins/admin/username-${random_id.suffix.hex}"
  type  = "String"
  value = "admin"

  tags = {
    Name = "jenkins-admin-username-${random_id.suffix.hex}"
  }
}

resource "aws_ssm_parameter" "jenkins_admin_password" {
  name  = "/jenkins/admin/password-${random_id.suffix.hex}"
  type  = "SecureString"
  value = random_password.jenkins_admin_password.result

  tags = {
    Name = "jenkins-admin-password-${random_id.suffix.hex}"
  }
}

resource "aws_instance" "jenkins" {
  tags                        = { "Name" = "jenkins-ec2-${random_id.suffix.hex}" }
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = var.instance_type
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  vpc_security_group_ids      = [aws_security_group.jenkins_sg.id]
  subnet_id                   = module.vpc.public_subnets[0]
  associate_public_ip_address = true
  monitoring                  = false
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  user_data = templatefile("${path.module}/templates/jenkins_user_data.tpl", {
    region        = data.aws_region.current.name
    random_suffix = random_id.suffix.hex
  })

  root_block_device {
    volume_type = "gp3"
    volume_size = 30
    encrypted   = true
  }
}
