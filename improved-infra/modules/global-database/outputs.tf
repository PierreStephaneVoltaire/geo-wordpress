output "global_cluster_id" {
  description = "RDS Global Cluster identifier"
  value       = aws_rds_global_cluster.wordpress.id
}

output "global_cluster_arn" {
  description = "RDS Global Cluster ARN"
  value       = aws_rds_global_cluster.wordpress.arn
}

output "primary_cluster_id" {
  description = "Primary RDS cluster identifier"
  value       = aws_rds_cluster.primary.id
}

output "primary_cluster_endpoint" {
  description = "Primary RDS cluster endpoint (writer)"
  value       = aws_rds_cluster.primary.endpoint
}

output "primary_cluster_reader_endpoint" {
  description = "Primary RDS cluster reader endpoint"
  value       = aws_rds_cluster.primary.reader_endpoint
}

output "secondary_cluster_endpoints" {
  description = "Secondary RDS cluster endpoints by region"
  value = {
    for region_name, cluster in aws_rds_cluster.secondary :
    region_name => cluster.endpoint
  }
}

output "secondary_cluster_reader_endpoints" {
  description = "Secondary RDS cluster reader endpoints by region"
  value = {
    for region_name, cluster in aws_rds_cluster.secondary :
    region_name => cluster.reader_endpoint
  }
}