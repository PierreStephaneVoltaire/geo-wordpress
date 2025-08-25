
# secondary Networks (Secondary - Created First, no peering)
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

# Singapore Network (Primary - Creates peering to all secondaries)
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

  # Pass all secondary VPC IDs to Singapore as a map
  peer_vpc_ids = {
    "${local.all_region_configs["ireland"].aws_region}" = module.ireland_network[0].vpc_id
  }

  tags = var.common_tags

  depends_on = [module.ireland_network]
}

# Accept peering connections in secondary regions
resource "aws_vpc_peering_connection_accepter" "ireland_accept" {
  count    = contains(keys(local.all_region_configs), "ireland") ? 1 : 0
  provider = aws.ireland

  vpc_peering_connection_id = module.singapore_network[0].peering_connection_ids["eu-west-1"]
  auto_accept               = true

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-peering-accepter-ireland"
  })
}

# Routes from secondary regions back to Singapore
resource "aws_route" "ireland_to_singapore" {
  count    = contains(keys(local.all_region_configs), "ireland") ? 1 : 0
  provider = aws.ireland

  route_table_id            = module.ireland_network[0].public_route_table_ids[0]
  destination_cidr_block    = local.vpc_cidrs["singapore"]
  vpc_peering_connection_id = module.singapore_network[0].peering_connection_ids["eu-west-1"]

  depends_on = [aws_vpc_peering_connection_accepter.ireland_accept]
}

# Routes from Singapore to secondary regions
resource "aws_route" "singapore_to_ireland" {
  count    = contains(keys(local.all_region_configs), "singapore") ? 1 : 0
  provider = aws.singapore

  route_table_id            = module.singapore_network[0].public_route_table_ids[0]
  destination_cidr_block    = local.vpc_cidrs["ireland"]
  vpc_peering_connection_id = module.singapore_network[0].peering_connection_ids["eu-west-1"]

  depends_on = [aws_vpc_peering_connection_accepter.ireland_accept]
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
