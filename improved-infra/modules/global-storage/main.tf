terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0"
    }
  }
}

# Get primary region for S3 bucket placement
locals {
  primary_region = [for k, v in var.regions : v.region if v.is_primary == true][0]
  replica_regions = [for k, v in var.regions : v.region if v.is_primary == false]
}

# Primary S3 bucket for WordPress media uploads
resource "aws_s3_bucket" "wordpress_media" {
  bucket = "${var.project_name}-media-${var.environment}-${var.random_suffix}"
  
  tags = merge(var.tags, {
    Name = "${var.project_name}-media-primary-${var.random_suffix}"
    Type = "Primary"
  })
}

# S3 bucket versioning
resource "aws_s3_bucket_versioning" "wordpress_media" {
  bucket = aws_s3_bucket.wordpress_media.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 bucket server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "wordpress_media" {
  bucket = aws_s3_bucket.wordpress_media.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 bucket public access block (allow public read for website assets)
resource "aws_s3_bucket_public_access_block" "wordpress_media" {
  bucket = aws_s3_bucket.wordpress_media.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# S3 bucket policy for public read access to media files
resource "aws_s3_bucket_policy" "wordpress_media" {
  bucket = aws_s3_bucket.wordpress_media.id
  depends_on = [aws_s3_bucket_public_access_block.wordpress_media]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.wordpress_media.arn}/*"
      }
    ]
  })
}

# S3 bucket CORS configuration for WordPress
resource "aws_s3_bucket_cors_configuration" "wordpress_media" {
  bucket = aws_s3_bucket.wordpress_media.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST", "DELETE", "HEAD"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

# Replica buckets for cross-region replication
resource "aws_s3_bucket" "wordpress_media_replica" {
  for_each = toset(local.replica_regions)
  
  provider = aws # This will need to be configured per region in the calling module
  bucket   = "${var.project_name}-media-replica-${each.key}-${var.environment}-${var.random_suffix}"
  
  tags = merge(var.tags, {
    Name = "${var.project_name}-media-replica-${each.key}-${var.random_suffix}"
    Type = "Replica"
    Region = each.key
  })
}

# Versioning for replica buckets
resource "aws_s3_bucket_versioning" "wordpress_media_replica" {
  for_each = aws_s3_bucket.wordpress_media_replica
  
  bucket = each.value.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Server-side encryption for replica buckets
resource "aws_s3_bucket_server_side_encryption_configuration" "wordpress_media_replica" {
  for_each = aws_s3_bucket.wordpress_media_replica
  
  bucket = each.value.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# IAM role for S3 replication
resource "aws_iam_role" "s3_replication" {
  name = "${var.project_name}-s3-replication-${var.random_suffix}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# IAM policy for S3 replication
resource "aws_iam_role_policy" "s3_replication" {
  name = "${var.project_name}-s3-replication-policy-${var.random_suffix}"
  role = aws_iam_role.s3_replication.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionTagging"
        ]
        Effect = "Allow"
        Resource = "${aws_s3_bucket.wordpress_media.arn}/*"
      },
      {
        Action = [
          "s3:ListBucket"
        ]
        Effect = "Allow"
        Resource = aws_s3_bucket.wordpress_media.arn
      },
      {
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags"
        ]
        Effect = "Allow"
        Resource = [for bucket in aws_s3_bucket.wordpress_media_replica : "${bucket.arn}/*"]
      }
    ]
  })
}

# S3 bucket replication configuration
resource "aws_s3_bucket_replication_configuration" "wordpress_media" {
  count = length(local.replica_regions) > 0 ? 1 : 0
  
  role   = aws_iam_role.s3_replication.arn
  bucket = aws_s3_bucket.wordpress_media.id

  dynamic "rule" {
    for_each = local.replica_regions
    content {
      id     = "ReplicateTo${title(rule.value)}"
      status = "Enabled"

      destination {
        bucket        = aws_s3_bucket.wordpress_media_replica[rule.value].arn
        storage_class = "STANDARD_IA"
      }
    }
  }

  depends_on = [aws_s3_bucket_versioning.wordpress_media]
}