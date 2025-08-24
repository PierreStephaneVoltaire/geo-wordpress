
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0"
    }
  }
}

resource "aws_s3_bucket" "wordpress_uploads" {
  bucket = "${var.project_name}-uploads-${var.random_suffix}"
  tags   = var.tags
}

resource "aws_s3_bucket_public_access_block" "wordpress_uploads" {
  bucket = aws_s3_bucket.wordpress_uploads.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_ssm_parameter" "db_password" {

  name      = "/${var.project_name}/${var.environment}/db/password"
  type      = "SecureString"
  value     = var.db_password
  overwrite = true
}

resource "aws_ssm_parameter" "db_username" {

  name      = "/${var.project_name}/${var.environment}/db/username"
  type      = "String"
  value     = var.db_username
  overwrite = true


}

resource "aws_ssm_parameter" "db_endpoint" {

  name      = "/${var.project_name}/${var.environment}/db/endpoint"
  type      = "String"
  value     = var.db_endpoint
  overwrite = true


}

resource "aws_ssm_parameter" "ireland_db_endpoint" {
  provider = aws.ireland

  name      = "/${var.project_name}/${var.environment}/ireland/db/endpoint"
  type      = "String"
  value     = var.ireland_db_endpoint
  overwrite = true


}

resource "aws_ssm_parameter" "ireland_db_username" {
  provider = aws.ireland

  name      = "/${var.project_name}/${var.environment}/ireland/db/username"
  type      = "String"
  value     = var.db_username
  overwrite = true


}

resource "aws_ssm_parameter" "ireland_db_password" {
  provider = aws.ireland

  name      = "/${var.project_name}/${var.environment}/ireland/db/password"
  type      = "SecureString"
  value     = var.db_password
  overwrite = true


}

resource "aws_ssm_parameter" "s3_bucket_name" {
  provider  = aws.singapore
  name      = "/${var.project_name}/${var.environment}/s3/bucket"
  type      = "String"
  value     = aws_s3_bucket.wordpress_uploads.bucket
  overwrite = true


}
resource "aws_ssm_parameter" "s3_bucket_name_ireland" {
  provider  = aws.ireland
  name      = "/${var.project_name}/${var.environment}/s3/bucket"
  type      = "String"
  value     = aws_s3_bucket.wordpress_uploads.bucket
  overwrite = true


}


resource "aws_ssm_parameter" "wp_admin_password" {

  provider  = aws.singapore
  name      = "/${var.project_name}/${var.environment}/wordpress/admin_password"
  type      = "SecureString"
  value     = var.wp_admin_password
  overwrite = true


}
resource "aws_ssm_parameter" "wp_admin_password_ireland" {

  provider  = aws.ireland
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
