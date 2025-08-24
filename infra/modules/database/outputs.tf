output "db_endpoint" {
  description = "RDS instance endpoint"
  value       = var.create_read_replica ? aws_db_instance.wordpress_replica[0].endpoint : aws_db_instance.wordpress[0].endpoint
}

output "db_identifier" {
  description = "RDS instance identifier"
  value       = var.create_read_replica ? aws_db_instance.wordpress_replica[0].identifier : aws_db_instance.wordpress[0].identifier
}

output "db_arn" {
  description = "Database ARN"
  value       = var.create_read_replica ? aws_db_instance.wordpress_replica[0].arn : aws_db_instance.wordpress[0].arn
}

output "db_instance_arn" {
  description = "Database instance ARN for read replicas"
  value       = var.create_read_replica ? null : aws_db_instance.wordpress[0].arn
}
