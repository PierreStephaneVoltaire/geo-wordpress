output "s3_bucket_name" {
  description = "S3 bucket name for uploads"
  value       = module.data.s3_bucket_name
}

output "primary_database_endpoint" {
  description = "Primary database endpoint"
  value       = module.database.db_endpoint
}

output "secondary_database_endpoints" {
  description = "Secondary region database endpoints"
  value = {
    for region_name, replica in module.database_replicas : region_name => replica.db_endpoint
  }
}

output "regions_deployed" {
  description = "List of regions where infrastructure is deployed"
  value = {
    primary   = local.primary_region
    secondary = local.secondary_regions
    all       = keys(local.all_region_configs)
  }
}

output "load_balancer_endpoints" {
  description = "Load balancer endpoints by region"
  value = {
    for region_name, compute in local.compute :
    region_name => compute != null ? compute.alb_dns_name : null
    if compute != null
  }
}

output "parameter_store_prefix" {
  description = "Parameter Store prefix for database credentials"
  value       = "/${var.project_name}/${var.environment}"
}

