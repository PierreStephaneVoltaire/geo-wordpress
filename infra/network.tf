
# Singapore Network
module "singapore_network" {
  count  = contains(keys(local.all_region_configs), "singapore") ? 1 : 0
  source = "./modules/network"

  providers = {
    aws           = aws.singapore
    aws.us_east_1 = aws.us_east_1
  }

  region       = local.all_region_configs["singapore"].aws_region
  vpc_cidr     = local.all_region_configs["singapore"].vpc_cidr
  project_name = var.project_name
  environment  = var.environment

  tags = var.common_tags
}

# Ireland Network
module "ireland_network" {
  count  = contains(keys(local.all_region_configs), "ireland") ? 1 : 0
  source = "./modules/network"

  providers = {
    aws           = aws.ireland
    aws.us_east_1 = aws.us_east_1
  }

  region       = local.all_region_configs["ireland"].aws_region
  vpc_cidr     = local.all_region_configs["ireland"].vpc_cidr
  project_name = var.project_name
  environment  = var.environment

  tags = var.common_tags
}

# Create a local map to reference network modules uniformly
locals {
  network = {
    for region_name in keys(local.all_region_configs) :
    region_name => region_name == "singapore" ? (
      length(module.singapore_network) > 0 ? module.singapore_network[0] : null
      ) : region_name == "ireland" ? (
      length(module.ireland_network) > 0 ? module.ireland_network[0] : null
    ) : null
  }
}



# Singapore Security Groups
module "singapore_alb_sg" {
  count  = contains(keys(local.all_region_configs), "singapore") ? 1 : 0
  source = "./modules/security"

  providers = {
    aws = aws.singapore
  }

  vpc_id              = local.network["singapore"].vpc_id
  project_name        = var.project_name
  region              = local.all_region_configs["singapore"].aws_region
  security_group_type = "alb"

  tags = var.common_tags
}

module "singapore_ec2_sg" {
  count  = contains(keys(local.all_region_configs), "singapore") ? 1 : 0
  source = "./modules/security"

  providers = {
    aws = aws.singapore
  }

  vpc_id                    = local.network["singapore"].vpc_id
  project_name              = var.project_name
  region                    = local.all_region_configs["singapore"].aws_region
  security_group_type       = "ec2"
  source_security_group_ids = length(module.singapore_alb_sg) > 0 ? [module.singapore_alb_sg[0].security_group_id] : []
  s3_bucket_name            = module.data.s3_bucket_name
  parameter_store_prefix    = "/${var.project_name}/${var.environment}"

  tags = var.common_tags
}

module "singapore_rds_sg" {
  count  = contains(keys(local.all_region_configs), "singapore") ? 1 : 0
  source = "./modules/security"

  providers = {
    aws = aws.singapore
  }

  vpc_id                    = local.network["singapore"].vpc_id
  project_name              = var.project_name
  region                    = local.all_region_configs["singapore"].aws_region
  security_group_type       = "rds"
  allowed_cidr_blocks       = values(local.vpc_cidrs)
  source_security_group_ids = length(module.singapore_ec2_sg) > 0 ? [module.singapore_ec2_sg[0].security_group_id] : []

  tags = var.common_tags
}

# Ireland Security Groups
module "ireland_alb_sg" {
  count  = contains(keys(local.all_region_configs), "ireland") ? 1 : 0
  source = "./modules/security"

  providers = {
    aws = aws.ireland
  }

  vpc_id              = local.network["ireland"].vpc_id
  project_name        = var.project_name
  region              = local.all_region_configs["ireland"].aws_region
  security_group_type = "alb"

  tags = var.common_tags
}

module "ireland_ec2_sg" {
  count  = contains(keys(local.all_region_configs), "ireland") ? 1 : 0
  source = "./modules/security"

  providers = {
    aws = aws.ireland
  }

  vpc_id                    = local.network["ireland"].vpc_id
  project_name              = var.project_name
  region                    = local.all_region_configs["ireland"].aws_region
  security_group_type       = "ec2"
  source_security_group_ids = length(module.ireland_alb_sg) > 0 ? [module.ireland_alb_sg[0].security_group_id] : []
  s3_bucket_name            = module.data.s3_bucket_name
  parameter_store_prefix    = "/${var.project_name}/${var.environment}"

  tags = var.common_tags
}

module "ireland_rds_sg" {
  count  = contains(keys(local.all_region_configs), "ireland") ? 1 : 0
  source = "./modules/security"

  providers = {
    aws = aws.ireland
  }

  vpc_id                    = local.network["ireland"].vpc_id
  project_name              = var.project_name
  region                    = local.all_region_configs["ireland"].aws_region
  security_group_type       = "rds"
  allowed_cidr_blocks       = values(local.vpc_cidrs)
  source_security_group_ids = length(module.ireland_ec2_sg) > 0 ? [module.ireland_ec2_sg[0].security_group_id] : []

  tags = var.common_tags
}

# Create local maps to reference security group modules uniformly
locals {
  alb_security_groups = {
    for region_name in keys(local.all_region_configs) :
    region_name => region_name == "singapore" ? (
      length(module.singapore_alb_sg) > 0 ? module.singapore_alb_sg[0] : null
      ) : region_name == "ireland" ? (
      length(module.ireland_alb_sg) > 0 ? module.ireland_alb_sg[0] : null
    ) : null
  }

  ec2_security_groups = {
    for region_name in keys(local.all_region_configs) :
    region_name => region_name == "singapore" ? (
      length(module.singapore_ec2_sg) > 0 ? module.singapore_ec2_sg[0] : null
      ) : region_name == "ireland" ? (
      length(module.ireland_ec2_sg) > 0 ? module.ireland_ec2_sg[0] : null
    ) : null
  }

  rds_security_groups = {
    for region_name in keys(local.all_region_configs) :
    region_name => region_name == "singapore" ? (
      length(module.singapore_rds_sg) > 0 ? module.singapore_rds_sg[0] : null
      ) : region_name == "ireland" ? (
      length(module.ireland_rds_sg) > 0 ? module.ireland_rds_sg[0] : null
    ) : null
  }
}
