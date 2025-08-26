output "parameter_prefix" {
  description = "Parameter Store prefix for all WordPress parameters"
  value       = "/${var.project_name}/${var.environment}"
}

output "db_username_parameter" {
  description = "Parameter Store name for database username"
  value       = aws_ssm_parameter.db_username.name
}

output "db_password_parameter" {
  description = "Parameter Store name for database password"
  value       = aws_ssm_parameter.db_password.name
}

output "wp_admin_email_parameter" {
  description = "Parameter Store name for WordPress admin email"
  value       = aws_ssm_parameter.wp_admin_email.name
}

output "wp_admin_password_parameter" {
  description = "Parameter Store name for WordPress admin password"
  value       = aws_ssm_parameter.wp_admin_password.name
}

output "s3_bucket_name_parameter" {
  description = "Parameter Store name for S3 bucket name"
  value       = aws_ssm_parameter.s3_bucket_name.name
}

output "cloudfront_domain_parameter" {
  description = "Parameter Store name for CloudFront domain"
  value       = aws_ssm_parameter.cloudfront_domain.name
}