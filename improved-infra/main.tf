terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

# Generate random suffix for all resource names
resource "random_id" "suffix" {
  byte_length = 2
}

# Create regions map based on requirements
locals {
  regions = var.regions
  primary_region = [for k, v in local.regions : k if v.is_primary == true][0]
  
  common_tags = merge(var.common_tags, {
    RandomSuffix = random_id.suffix.hex
  })
}

# Generate passwords
resource "random_password" "db_password" {
  length  = 16
  special = true
}

resource "random_password" "wp_admin_password" {
  length  = 16
  special = true
}

# Global S3 bucket for WordPress media with cross-region replication
module "global_storage" {
  source = "./modules/global-storage"
  
  project_name  = var.project_name
  environment   = var.environment
  random_suffix = random_id.suffix.hex
  regions       = local.regions
  
  tags = local.common_tags
}

# Aurora Global Database
module "global_database" {
  source = "./modules/global-database"
  
  project_name  = var.project_name
  environment   = var.environment
  random_suffix = random_id.suffix.hex
  regions       = local.regions
  
  db_username = var.db_username
  db_password = random_password.db_password.result
  db_name     = var.db_name
  
  aurora_instance_class = var.aurora_instance_class
  aurora_instance_count = var.aurora_instance_count
  
  regional_infrastructure = {
    for region_name in keys(local.regions) :
    region_name => {
      db_subnet_group_name  = module.regional_infrastructure[region_name].db_subnet_group_name
      rds_security_group_id = module.regional_infrastructure[region_name].rds_security_group_id
    }
  }
  
  depends_on = [module.regional_infrastructure]
  
  tags = local.common_tags
  
}

# Regional Infrastructure for each region
module "regional_infrastructure" {
  for_each = local.regions
  source   = "./modules/regional-infrastructure"
  
  region_name   = each.key
  region_config = each.value
  
  project_name  = var.project_name
  environment   = var.environment
  random_suffix = random_id.suffix.hex
  
  tags = local.common_tags
}

# Parameter Store configuration (global)
module "parameter_store" {
  source = "./modules/parameter-store"
  
  project_name  = var.project_name
  environment   = var.environment
  
  db_username       = var.db_username
  db_password       = random_password.db_password.result
  wp_admin_password = random_password.wp_admin_password.result
  admin_email       = var.admin_email
  
  s3_bucket_name = module.global_storage.primary_bucket_name
  
  db_primary_endpoint = module.global_database.primary_cluster_endpoint
  db_secondary_endpoints = module.global_database.secondary_cluster_endpoints
  cloudfront_domain = "" # Will be updated after CloudFront is created
  
  regions = local.regions
  
  depends_on = [module.global_database]
  
  tags = local.common_tags
}

# ECS Fargate services for each region
module "wordpress_fargate" {
  for_each = local.regions
  source   = "./modules/wordpress-fargate"
  
  region_name   = each.key
  region_config = each.value
  
  project_name  = var.project_name
  environment   = var.environment
  random_suffix = random_id.suffix.hex
  
  vpc_id                        = module.regional_infrastructure[each.key].vpc_id
  private_subnet_ids            = module.regional_infrastructure[each.key].private_subnet_ids
  public_subnet_ids             = module.regional_infrastructure[each.key].public_subnet_ids
  alb_security_group_id         = module.regional_infrastructure[each.key].alb_security_group_id
  ecs_security_group_id         = module.regional_infrastructure[each.key].ecs_security_group_id
  redis_security_group_id       = module.regional_infrastructure[each.key].redis_security_group_id
  elasticache_subnet_group_name = module.regional_infrastructure[each.key].elasticache_subnet_group_name
  
  s3_bucket_name = module.global_storage.primary_bucket_name
  
  db_primary_endpoint = each.value.is_primary ? module.global_database.primary_cluster_endpoint : ""
  db_replica_endpoint = each.value.is_primary ? "" : lookup(module.global_database.secondary_cluster_endpoints, each.key, "")
  
  fargate_cpu    = var.fargate_cpu
  fargate_memory = var.fargate_memory
  
  depends_on = [module.regional_infrastructure, module.global_database, module.parameter_store]
  
  tags = local.common_tags
  
}

# CloudFront distribution with Lambda@Edge
module "cloudfront" {
  source = "./modules/cloudfront"
  
  project_name  = var.project_name
  environment   = var.environment
  random_suffix = random_id.suffix.hex
  
  regions = local.regions
  
  # ALB origins from regional infrastructure
  alb_origins = {
    for region_name, config in local.regions :
    region_name => module.wordpress_fargate[region_name].alb_dns_name
  }
  
  s3_bucket_domain = module.global_storage.primary_bucket_domain
  
  geoblocking_countries = var.geoblocking_countries
  
  depends_on = [module.wordpress_fargate]
  
  tags = local.common_tags
  
}