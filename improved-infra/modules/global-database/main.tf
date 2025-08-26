terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0"
    }
  }
}

# Data to get regional infrastructure outputs
locals {
  primary_region_name = [for k, v in var.regions : k if v.is_primary == true][0]
  primary_region_code = [for k, v in var.regions : v.region if v.is_primary == true][0]
  
  replica_regions = {
    for k, v in var.regions : k => v if v.is_primary == false
  }
}

# Aurora Global Cluster
resource "aws_rds_global_cluster" "wordpress" {
  global_cluster_identifier   = "${var.project_name}-global-${var.random_suffix}"
  database_name              = var.db_name
  engine                     = "aurora-mysql"
  engine_version             = "8.0.mysql_aurora.3.02.0"
  storage_encrypted          = true
  deletion_protection        = false # Set to true for production
  
  tags = var.tags
}

# Primary Aurora cluster (writer)
resource "aws_rds_cluster" "primary" {
  region = local.primary_region_code

  cluster_identifier          = "${var.project_name}-primary-${local.primary_region_name}-${var.random_suffix}"
  global_cluster_identifier   = aws_rds_global_cluster.wordpress.id
  engine                      = aws_rds_global_cluster.wordpress.engine
  engine_version              = aws_rds_global_cluster.wordpress.engine_version
  database_name               = var.db_name
  master_username             = var.db_username
  master_password             = var.db_password
  
  db_subnet_group_name   = var.regional_infrastructure[local.primary_region_name].db_subnet_group_name
  vpc_security_group_ids = [var.regional_infrastructure[local.primary_region_name].rds_security_group_id]
  
  storage_encrypted               = true
  backup_retention_period         = 7
  preferred_backup_window         = "03:00-04:00"
  preferred_maintenance_window    = "sun:04:00-sun:05:00"
  
  skip_final_snapshot = true # Set to false for production
  
  # Enable backup export to S3
  enabled_cloudwatch_logs_exports = ["error", "general", "slowquery"]
  
  tags = merge(var.tags, {
    Name = "${var.project_name}-primary-cluster-${local.primary_region_name}-${var.random_suffix}"
    Role = "Primary"
  })
  
  depends_on = [aws_rds_global_cluster.wordpress]
}

# Primary Aurora cluster instances
resource "aws_rds_cluster_instance" "primary" {
  count = var.aurora_instance_count # Configurable count for cost optimization

  region = local.primary_region_code

  identifier           = "${var.project_name}-primary-${count.index}-${local.primary_region_name}-${var.random_suffix}"
  cluster_identifier   = aws_rds_cluster.primary.id
  instance_class       = var.aurora_instance_class # Configurable instance size
  engine               = aws_rds_cluster.primary.engine
  engine_version       = aws_rds_cluster.primary.engine_version
  
  performance_insights_enabled = true
  monitoring_interval         = 60
  monitoring_role_arn         = aws_iam_role.rds_enhanced_monitoring.arn
  
  tags = merge(var.tags, {
    Name = "${var.project_name}-primary-instance-${count.index}-${local.primary_region_name}-${var.random_suffix}"
  })
}

# Secondary Aurora clusters (readers)
resource "aws_rds_cluster" "secondary" {
  for_each = local.replica_regions

  region = each.value.region

  cluster_identifier          = "${var.project_name}-secondary-${each.key}-${var.random_suffix}"
  global_cluster_identifier   = aws_rds_global_cluster.wordpress.id
  engine                      = aws_rds_global_cluster.wordpress.engine
  engine_version              = aws_rds_global_cluster.wordpress.engine_version
  
  db_subnet_group_name   = var.regional_infrastructure[each.key].db_subnet_group_name
  vpc_security_group_ids = [var.regional_infrastructure[each.key].rds_security_group_id]
  
  storage_encrypted = true
  
  skip_final_snapshot = true # Set to false for production
  
  enabled_cloudwatch_logs_exports = ["error", "general", "slowquery"]
  
  tags = merge(var.tags, {
    Name = "${var.project_name}-secondary-cluster-${each.key}-${var.random_suffix}"
    Role = "Secondary"
  })
  
  depends_on = [aws_rds_cluster_instance.primary]
}

# Secondary Aurora cluster instances
resource "aws_rds_cluster_instance" "secondary" {
  for_each = local.replica_regions

  region = each.value.region

  identifier           = "${var.project_name}-secondary-${each.key}-${var.random_suffix}"
  cluster_identifier   = aws_rds_cluster.secondary[each.key].id
  instance_class       = var.aurora_instance_class # Use same configurable instance size
  engine               = aws_rds_cluster.secondary[each.key].engine
  engine_version       = aws_rds_cluster.secondary[each.key].engine_version
  
  performance_insights_enabled = true
  monitoring_interval         = 60
  monitoring_role_arn         = aws_iam_role.rds_enhanced_monitoring.arn
  
  tags = merge(var.tags, {
    Name = "${var.project_name}-secondary-instance-${each.key}-${var.random_suffix}"
  })
}

# IAM role for RDS Enhanced Monitoring
resource "aws_iam_role" "rds_enhanced_monitoring" {
  name = "${var.project_name}-rds-monitoring-${var.random_suffix}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  role       = aws_iam_role.rds_enhanced_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}