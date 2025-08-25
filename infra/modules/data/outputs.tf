output "s3_bucket_name" {
  description = "S3 bucket name for WordPress uploads"
  value       = aws_s3_bucket.wordpress_uploads.bucket
}

output "s3_bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.wordpress_uploads.arn
}


output "primary_db_endpoint_param" {
  description = "Name of the primary database endpoint SSM parameter"
  value       = aws_ssm_parameter.primary_db_endpoint.name
}

output "primary_db_username_param" {
  description = "Name of the primary database username SSM parameter"
  value       = aws_ssm_parameter.primary_db_username.name
}

output "primary_db_password_param" {
  description = "Name of the primary database password SSM parameter"
  value       = aws_ssm_parameter.primary_db_password.name
}

output "secondary_db_endpoint_params" {
  description = "Map of secondary region database endpoint SSM parameter names"
  value = {
    for region_name, param in aws_ssm_parameter.secondary_db_endpoint : region_name => param.name
  }
}

output "secondary_db_username_params" {
  description = "Map of secondary region database username SSM parameter names"
  value = {
    for region_name, param in aws_ssm_parameter.secondary_db_username : region_name => param.name
  }
}

output "secondary_db_password_params" {
  description = "Map of secondary region database password SSM parameter names"
  value = {
    for region_name, param in aws_ssm_parameter.secondary_db_password : region_name => param.name
  }
}


output "s3_bucket_param" {
  description = "Name of the S3 bucket SSM parameter"
  value       = aws_ssm_parameter.s3_bucket_name.name
}
