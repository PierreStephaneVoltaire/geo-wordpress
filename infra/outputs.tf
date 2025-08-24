output "s3_bucket_name" {
  description = "S3 bucket name for uploads"
  value       = module.data.s3_bucket_name
}

output "database_endpoint" {
  description = "Centralized MariaDB endpoint"
  value       = module.database.db_endpoint
}

output "parameter_store_prefix" {
  description = "Parameter Store prefix for database credentials"
  value       = "/${var.project_name}/${var.environment}"
}
