
# Singapore Network
module "singapore_network" {
  source = "./modules/network"

  providers = {
    aws           = aws.singapore
    aws.us_east_1 = aws.us_east_1
  }

  region          = var.regions.singapore
  vpc_cidr        = var.vpc_cidrs.singapore
  project_name    = var.project_name
  environment     = var.environment
  is_database_vpc = true # Create database subnets

  # CloudFront configuration (only for primary region) - disabled for now due to dependencies
  create_cloudfront = false
  singapore_alb_dns = ""
  ireland_alb_dns   = ""

  tags = var.common_tags
}

# Ireland Network
module "ireland_network" {
  source = "./modules/network"

  providers = {
    aws           = aws.ireland
    aws.us_east_1 = aws.us_east_1
  }

  region          = var.regions.ireland
  vpc_cidr        = var.vpc_cidrs.ireland
  project_name    = var.project_name
  environment     = var.environment
  is_database_vpc = true # Create database subnets

  # CloudFront configuration (disabled for secondary region)
  create_cloudfront = false
  singapore_alb_dns = ""
  ireland_alb_dns   = ""

  tags = var.common_tags
}



# Singapore Security Groups
module "singapore_alb_sg" {
  source = "./modules/security"

  providers = {
    aws = aws.singapore
  }

  vpc_id              = module.singapore_network.vpc_id
  project_name        = var.project_name
  region              = var.regions.singapore
  security_group_type = "alb"

  tags = var.common_tags
}

module "singapore_ec2_sg" {
  source = "./modules/security"

  providers = {
    aws = aws.singapore
  }

  vpc_id                    = module.singapore_network.vpc_id
  project_name              = var.project_name
  region                    = var.regions.singapore
  security_group_type       = "ec2"
  source_security_group_ids = [module.singapore_alb_sg.security_group_id]
  s3_bucket_name            = module.data.s3_bucket_name
  parameter_store_prefix    = "/${var.project_name}/${var.environment}"

  tags = var.common_tags
}

module "singapore_rds_sg" {
  source = "./modules/security"

  providers = {
    aws = aws.singapore
  }

  vpc_id                    = module.singapore_network.vpc_id
  project_name              = var.project_name
  region                    = var.regions.singapore
  security_group_type       = "rds"
  allowed_cidr_blocks       = [var.vpc_cidrs.singapore, var.vpc_cidrs.ireland]
  source_security_group_ids = [module.singapore_ec2_sg.security_group_id]

  tags = var.common_tags
}

# Ireland Security Groups
module "ireland_alb_sg" {
  source = "./modules/security"

  providers = {
    aws = aws.ireland
  }

  vpc_id              = module.ireland_network.vpc_id
  project_name        = var.project_name
  region              = var.regions.ireland
  security_group_type = "alb"

  tags = var.common_tags
}

module "ireland_ec2_sg" {
  source = "./modules/security"

  providers = {
    aws = aws.ireland
  }

  vpc_id                    = module.ireland_network.vpc_id
  project_name              = var.project_name
  region                    = var.regions.ireland
  security_group_type       = "ec2"
  source_security_group_ids = [module.ireland_alb_sg.security_group_id]
  s3_bucket_name            = module.data.s3_bucket_name
  parameter_store_prefix    = "/${var.project_name}/${var.environment}"

  tags = var.common_tags
}

module "ireland_rds_sg" {
  source = "./modules/security"

  providers = {
    aws = aws.ireland
  }

  vpc_id                    = module.ireland_network.vpc_id
  project_name              = var.project_name
  region                    = var.regions.ireland
  security_group_type       = "rds"
  allowed_cidr_blocks       = [var.vpc_cidrs.singapore, var.vpc_cidrs.ireland]
  source_security_group_ids = [module.ireland_ec2_sg.security_group_id]

  tags = var.common_tags
}
