terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = ">= 6.0.0"
      configuration_aliases = [aws.singapore, aws.ireland]
    }
  }
}

# NOTE: Provider Limitation
# This data module is partially generalized. Due to Terraform's limitation with
# dynamic provider assignment, secondary region parameters are currently limited
# to Ireland (aws.ireland provider). To fully support additional regions, you would
# need to add explicit provider configurations and conditional resources for each region.
#
# Future enhancement: Consider separating this into region-specific data modules
# or using a different approach for multi-region parameter management.

resource "aws_s3_bucket" "wordpress_uploads" {
  bucket = "${var.project_name}-uploads-${var.random_suffix}"
}

resource "aws_s3_bucket_public_access_block" "wordpress_uploads" {
  bucket = aws_s3_bucket.wordpress_uploads.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Primary region SSM parameters
resource "aws_ssm_parameter" "primary_db_endpoint" {
  provider  = aws.singapore
  name      = "/${var.project_name}/${var.environment}/db/endpoint"
  type      = "String"
  value     = var.db_endpoint
  overwrite = true
}

resource "aws_ssm_parameter" "primary_db_username" {
  provider  = aws.singapore
  name      = "/${var.project_name}/${var.environment}/db/username"
  type      = "String"
  value     = var.db_username
  overwrite = true
}

resource "aws_ssm_parameter" "primary_db_password" {
  provider  = aws.singapore
  name      = "/${var.project_name}/${var.environment}/db/password"
  type      = "SecureString"
  value     = var.db_password
  overwrite = true
}

# Secondary region SSM parameters (Ireland for now - can be extended)
resource "aws_ssm_parameter" "secondary_db_endpoint" {
  for_each = var.secondary_db_endpoints

  provider  = aws.ireland # Note: This limits us to Ireland for now
  name      = "/${var.project_name}/${var.environment}/${each.key}/db/endpoint"
  type      = "String"
  value     = each.value
  overwrite = true
}

resource "aws_ssm_parameter" "secondary_db_username" {
  for_each = var.secondary_db_endpoints

  provider  = aws.ireland # Note: This limits us to Ireland for now
  name      = "/${var.project_name}/${var.environment}/${each.key}/db/username"
  type      = "String"
  value     = var.db_username
  overwrite = true
}

resource "aws_ssm_parameter" "secondary_db_password" {
  for_each = var.secondary_db_endpoints

  provider  = aws.ireland # Note: This limits us to Ireland for now
  name      = "/${var.project_name}/${var.environment}/${each.key}/db/password"
  type      = "SecureString"
  value     = var.db_password
  overwrite = true
}

# S3 bucket name parameter in primary region
resource "aws_ssm_parameter" "s3_bucket_name" {
  provider  = aws.singapore
  name      = "/${var.project_name}/${var.environment}/s3/bucket"
  type      = "String"
  value     = aws_s3_bucket.wordpress_uploads.bucket
  overwrite = true
}

# S3 bucket name parameter in secondary regions
resource "aws_ssm_parameter" "s3_bucket_name_secondary" {
  for_each = var.secondary_db_endpoints

  provider  = aws.ireland # Note: This limits us to Ireland for now
  name      = "/${var.project_name}/${var.environment}/s3/bucket"
  type      = "String"
  value     = aws_s3_bucket.wordpress_uploads.bucket
  overwrite = true
}


# WordPress admin password in primary region
resource "aws_ssm_parameter" "wp_admin_password" {
  provider  = aws.singapore
  name      = "/${var.project_name}/${var.environment}/wordpress/admin_password"
  type      = "SecureString"
  value     = var.wp_admin_password
  overwrite = true
}

# WordPress admin password in secondary regions
resource "aws_ssm_parameter" "wp_admin_password_secondary" {
  for_each = var.secondary_db_endpoints

  provider  = aws.ireland # Note: This limits us to Ireland for now
  name      = "/${var.project_name}/${var.environment}/wordpress/admin_password"
  type      = "SecureString"
  value     = var.wp_admin_password
  overwrite = true
}

resource "aws_s3_bucket_policy" "wordpress_uploads" {
  bucket = aws_s3_bucket.wordpress_uploads.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.wordpress_uploads.arn}/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.wordpress_uploads]
}
