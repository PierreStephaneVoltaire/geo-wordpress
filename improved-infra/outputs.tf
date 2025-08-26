output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = module.cloudfront.distribution_id
}

output "cloudfront_distribution_domain_name" {
  description = "CloudFront distribution domain name"
  value       = module.cloudfront.distribution_domain_name
}

output "s3_bucket_name" {
  description = "Primary S3 bucket name for media uploads"
  value       = module.global_storage.primary_bucket_name
}

output "aurora_global_cluster_id" {
  description = "Aurora Global Database cluster identifier"
  value       = module.global_database.global_cluster_id
}

output "regional_alb_endpoints" {
  description = "Regional ALB DNS names for each region"
  value = {
    for region_name in keys(var.regions) :
    region_name => module.wordpress_fargate[region_name].alb_dns_name
  }
}

output "regional_vpc_ids" {
  description = "VPC IDs for each region"
  value = {
    for region_name in keys(var.regions) :
    region_name => module.regional_infrastructure[region_name].vpc_id
  }
}

output "ecs_cluster_names" {
  description = "ECS cluster names for each region"
  value = {
    for region_name in keys(var.regions) :
    region_name => module.wordpress_fargate[region_name].ecs_cluster_name
  }
}

output "random_suffix" {
  description = "Random suffix used for resource naming"
  value       = random_id.suffix.hex
}