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

locals {
  primary_region    = var.geo_regions.primary
  secondary_regions = var.geo_regions.secondary
  all_regions       = var.geo_regions.all
  vpc_cidrs         = var.geo_regions.vpc_cidrs

  # Create a combined list of all regions for iteration
  all_region_names = keys(var.geo_regions.all)

  # Create region-specific configurations
  primary_region_config = {
    (local.primary_region) = {
      region_name = local.primary_region
      aws_region  = local.all_regions[local.primary_region]
      vpc_cidr    = local.vpc_cidrs[local.primary_region]
      is_primary  = true
    }
  }

  secondary_region_configs = {
    for region in local.secondary_regions : region => {
      region_name = region
      aws_region  = local.all_regions[region]
      vpc_cidr    = local.vpc_cidrs[region]
      is_primary  = false
    }
  }

  all_region_configs = merge(local.primary_region_config, local.secondary_region_configs)
}


# Primary RDS instance (in the primary region)
module "database" {
  source = "./modules/database"

  providers = {
    aws = aws.singapore # Note: Update this manually when changing primary region
  }

  region                = local.all_regions[local.primary_region]
  project_name          = var.project_name
  environment           = var.environment
  db_username           = var.db_username
  db_password           = random_password.db_password.result
  public_subnet_ids     = local.network[local.primary_region].database_subnets
  rds_security_group_id = local.rds_security_groups[local.primary_region].security_group_id
  random_suffix         = random_id.suffix.hex

  tags = var.common_tags
}

# Secondary region database replicas
module "database_replicas" {
  for_each = local.secondary_region_configs
  source   = "./modules/database"

  providers = {
    aws = aws.ireland # Note: Update this manually when changing secondary regions
  }

  region                = each.value.aws_region
  project_name          = var.project_name
  environment           = var.environment
  db_username           = var.db_username
  db_password           = random_password.db_password.result
  public_subnet_ids     = local.network[each.key].database_subnets
  rds_security_group_id = local.rds_security_groups[each.key].security_group_id
  random_suffix         = random_id.suffix.hex

  create_read_replica  = true
  source_db_identifier = module.database.db_identifier
  source_db_arn        = module.database.db_instance_arn

  tags = var.common_tags
}

# Data module (S3 bucket for WordPress uploads and Parameter Store)
module "data" {
  source = "./modules/data"

  providers = {
    aws           = aws
    aws.ireland   = aws.ireland
    aws.singapore = aws.singapore
  }

  project_name  = var.project_name
  random_suffix = random_id.suffix.hex
  environment   = var.environment
  db_username   = var.db_username
  db_password   = random_password.db_password.result
  db_endpoint   = module.database.db_endpoint
  # Create a map of secondary region DB endpoints
  secondary_db_endpoints = {
    for region_name, replica in module.database_replicas : region_name => replica.db_endpoint
  }
  wp_admin_password = random_password.wp_admin_password.result

  tags = var.common_tags
}

# Singapore Compute (Primary)
module "singapore_compute" {
  count  = contains(keys(local.all_region_configs), "singapore") ? 1 : 0
  source = "./modules/compute"

  providers = {
    aws = aws.singapore
  }

  region                    = local.all_region_configs["singapore"].aws_region
  project_name              = var.project_name
  environment               = var.environment
  vpc_id                    = local.network["singapore"].vpc_id
  private_subnets           = local.network["singapore"].private_subnets
  public_subnets            = local.network["singapore"].public_subnets
  alb_security_group_id     = local.alb_security_groups["singapore"].security_group_id
  ec2_security_group_id     = local.ec2_security_groups["singapore"].security_group_id
  ec2_instance_profile_name = local.ec2_security_groups["singapore"].ec2_instance_profile_name
  instance_type             = var.instance_type
  min_size                  = var.min_size
  max_size                  = var.max_size
  desired_capacity          = var.desired_capacity
  s3_bucket_name            = module.data.s3_bucket_name
  db_endpoint               = local.all_region_configs["singapore"].is_primary ? module.database.db_endpoint : module.database_replicas["singapore"].db_endpoint
  parameter_store_prefix    = "/${var.project_name}/${var.environment}"

  user_data_template_vars = {
    region                    = local.all_region_configs["singapore"].aws_region
    db_region                 = local.all_region_configs["singapore"].aws_region
    project_name              = var.project_name
    environment               = var.environment
    db_endpoint_param         = local.all_region_configs["singapore"].is_primary ? module.data.primary_db_endpoint_param : module.data.secondary_db_endpoint_params["singapore"]
    db_username_param         = local.all_region_configs["singapore"].is_primary ? module.data.primary_db_username_param : module.data.secondary_db_username_params["singapore"]
    db_password_param         = local.all_region_configs["singapore"].is_primary ? module.data.primary_db_password_param : module.data.secondary_db_password_params["singapore"]
    s3_bucket_param           = module.data.s3_bucket_param
    primary_db_endpoint_param = module.data.primary_db_endpoint_param
    admin_email               = var.admin_email
    distribution_domain_name  = "placeholder-will-be-updated-after-cloudfront"
  }

  tags = var.common_tags
}

# Ireland Compute (Secondary)
module "ireland_compute" {
  count  = contains(keys(local.all_region_configs), "ireland") ? 1 : 0
  source = "./modules/compute"

  providers = {
    aws = aws.ireland
  }

  region                    = local.all_region_configs["ireland"].aws_region
  project_name              = var.project_name
  environment               = var.environment
  vpc_id                    = local.network["ireland"].vpc_id
  private_subnets           = local.network["ireland"].private_subnets
  public_subnets            = local.network["ireland"].public_subnets
  alb_security_group_id     = local.alb_security_groups["ireland"].security_group_id
  ec2_security_group_id     = local.ec2_security_groups["ireland"].security_group_id
  ec2_instance_profile_name = local.ec2_security_groups["ireland"].ec2_instance_profile_name
  instance_type             = var.instance_type
  min_size                  = var.min_size
  max_size                  = var.max_size
  desired_capacity          = var.desired_capacity
  s3_bucket_name            = module.data.s3_bucket_name
  db_endpoint               = local.all_region_configs["ireland"].is_primary ? module.database.db_endpoint : module.database_replicas["ireland"].db_endpoint
  parameter_store_prefix    = "/${var.project_name}/${var.environment}"

  user_data_template_vars = {
    region                    = local.all_region_configs["ireland"].aws_region
    db_region                 = local.all_region_configs["ireland"].aws_region
    project_name              = var.project_name
    environment               = var.environment
    db_endpoint_param         = local.all_region_configs["ireland"].is_primary ? module.data.primary_db_endpoint_param : module.data.secondary_db_endpoint_params["ireland"]
    db_username_param         = local.all_region_configs["ireland"].is_primary ? module.data.primary_db_username_param : module.data.secondary_db_username_params["ireland"]
    db_password_param         = local.all_region_configs["ireland"].is_primary ? module.data.primary_db_password_param : module.data.secondary_db_password_params["ireland"]
    s3_bucket_param           = module.data.s3_bucket_param
    primary_db_endpoint_param = module.data.primary_db_endpoint_param
    admin_email               = var.admin_email
    distribution_domain_name  = "placeholder-will-be-updated-after-cloudfront"
  }

  tags = var.common_tags
}

# Create a local map to reference compute modules uniformly for CloudFront
locals {
  compute = {
    for region_name in keys(local.all_region_configs) :
    region_name => region_name == "singapore" ? (
      length(module.singapore_compute) > 0 ? module.singapore_compute[0] : null
      ) : region_name == "ireland" ? (
      length(module.ireland_compute) > 0 ? module.ireland_compute[0] : null
    ) : null
  }
}
