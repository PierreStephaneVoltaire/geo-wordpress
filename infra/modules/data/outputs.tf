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
  value       = var.create_parameters ? aws_ssm_parameter.db_endpoint[0].name : "/${var.project_name}/${var.environment}/db/endpoint"
}

output "singapore_db_username_param" {
  description = "Name of the Singapore database username SSM parameter"
  value       = var.create_parameters ? aws_ssm_parameter.db_username[0].name : "/${var.project_name}/${var.environment}/db/username"
}

output "singapore_db_password_param" {
  description = "Name of the Singapore database password SSM parameter"
  value       = var.create_parameters ? aws_ssm_parameter.db_password[0].name : "/${var.project_name}/${var.environment}/db/password"
}


output "ireland_db_endpoint_param" {
  description = "Name of the Ireland database endpoint SSM parameter"
  value       = var.create_parameters ? aws_ssm_parameter.ireland_db_endpoint[0].name : "/${var.project_name}/${var.environment}/ireland/db/endpoint"
}

output "ireland_db_username_param" {
  description = "Name of the Ireland database username SSM parameter"
  value       = var.create_parameters ? aws_ssm_parameter.ireland_db_username[0].name : "/${var.project_name}/${var.environment}/ireland/db/username"
}

output "ireland_db_password_param" {
  description = "Name of the Ireland database password SSM parameter"
  value       = var.create_parameters ? aws_ssm_parameter.ireland_db_password[0].name : "/${var.project_name}/${var.environment}/ireland/db/password"
}


output "s3_bucket_param" {
  description = "Name of the S3 bucket SSM parameter"
  value       = var.create_parameters ? aws_ssm_parameter.s3_bucket_name[0].name : "/${var.project_name}/${var.environment}/s3/bucket"
}
