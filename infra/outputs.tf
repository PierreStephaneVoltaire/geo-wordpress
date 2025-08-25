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

output "deployment_instructions" {
  description = "Instructions for completing the deployment"
  value = {
    step_1              = "Primary region (Singapore) will deploy first and create WordPress tables"
    step_2              = "Secondary region (Ireland) starts with 0 instances to avoid race condition"
    step_3              = "After primary WordPress is ready, scale up Ireland with: terraform apply -var='desired_capacity=1'"
    step_4              = "Or update variables.tf to set desired_capacity=1 for Ireland specifically"
    primary_ready_check = "Check Singapore ALB endpoint to verify WordPress is installed"
    scale_up_command    = "To scale up secondary: terraform apply -target=module.ireland_compute -var='ireland_desired_capacity=1'"
  }
}
