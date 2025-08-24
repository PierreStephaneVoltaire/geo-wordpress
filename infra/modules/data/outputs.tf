output "s3_bucket_name" {
  description = "S3 bucket name for WordPress uploads"
  value       = aws_s3_bucket.wordpress_uploads.bucket
}

output "s3_bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.wordpress_uploads.arn
}


output "singapore_db_endpoint_param" {
  description = "Name of the Singapore database endpoint SSM parameter"
  value       = aws_ssm_parameter.db_endpoint.name
}

output "singapore_db_username_param" {
  description = "Name of the Singapore database username SSM parameter"
  value       = aws_ssm_parameter.db_username.name
}

output "singapore_db_password_param" {
  description = "Name of the Singapore database password SSM parameter"
  value       = aws_ssm_parameter.db_password.name
}


output "ireland_db_endpoint_param" {
  description = "Name of the Ireland database endpoint SSM parameter"
  value       = aws_ssm_parameter.ireland_db_endpoint.name
}

output "ireland_db_username_param" {
  description = "Name of the Ireland database username SSM parameter"
  value       = aws_ssm_parameter.ireland_db_username.name
}

output "ireland_db_password_param" {
  description = "Name of the Ireland database password SSM parameter"
  value       = aws_ssm_parameter.ireland_db_password.name
}


output "s3_bucket_param" {
  description = "Name of the S3 bucket SSM parameter"
  value       = aws_ssm_parameter.s3_bucket_name.name
}
