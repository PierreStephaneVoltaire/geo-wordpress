resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins-ssm-sg-${random_id.suffix.hex}"
  description = "Security group for Jenkins EC2 with SSM access"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }


  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ingress_cidr]
    description = "Jenkins Web UI"
  }

  tags = merge(
    var.tags,
    {
      Name = "jenkins-ssm-sg-${random_id.suffix.hex}"
    }
  )
}