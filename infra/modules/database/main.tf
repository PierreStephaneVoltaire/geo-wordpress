
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0"
    }
  }
}

resource "aws_db_subnet_group" "wordpress" {
  count      = var.create_read_replica ? 0 : 1
  name       = "${var.project_name}-${var.environment}-${var.region}-db-subnet-group-${var.random_suffix}"
  subnet_ids = var.public_subnet_ids

  tags = merge(var.tags, {
    Name = "${var.project_name}-db-subnet-group-${var.region}-${var.random_suffix}"
  })
}

resource "aws_db_subnet_group" "wordpress_replica" {
  count      = var.create_read_replica ? 1 : 0
  name       = "${var.project_name}-${var.environment}-replica-${var.region}-db-subnet-group-${var.random_suffix}"
  subnet_ids = var.public_subnet_ids

  tags = merge(var.tags, {
    Name = "${var.project_name}-replica-db-subnet-group-${var.region}-${var.random_suffix}"
  })
}

resource "aws_db_instance" "wordpress" {
  count      = var.create_read_replica ? 0 : 1
  identifier = "${var.project_name}-${var.environment}-${var.random_suffix}"

  engine         = "mariadb"
  engine_version = "10.11.8"
  instance_class = "db.t3.micro"

  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp2"
  storage_encrypted     = false

  db_name  = "wordpress"
  username = var.db_username
  password = var.db_password

  vpc_security_group_ids = [var.rds_security_group_id]
  db_subnet_group_name   = aws_db_subnet_group.wordpress[0].name

  backup_retention_period = 7
  backup_window           = "07:00-09:00"
  maintenance_window      = "Sun:05:00-Sun:06:00"

  skip_final_snapshot = true
  deletion_protection = false

  multi_az            = false
  publicly_accessible = false

  tags = merge(var.tags, {
    Name = "${var.project_name}-mariadb-${var.region}-${var.random_suffix}"
  })
}

resource "aws_db_instance" "wordpress_replica" {
  count               = var.create_read_replica ? 1 : 0
  identifier          = "${var.project_name}-${var.environment}-replica-${var.region}-${var.random_suffix}"
  replicate_source_db = var.source_db_arn

  instance_class = "db.t3.micro"

  vpc_security_group_ids = [var.rds_security_group_id]
  db_subnet_group_name   = aws_db_subnet_group.wordpress_replica[0].name

  skip_final_snapshot = true
  deletion_protection = false

  publicly_accessible = false

  tags = merge(var.tags, {
    Name = "${var.project_name}-mariadb-replica-${var.region}-${var.random_suffix}"
  })
}
