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


# Primary RDS instance in Singapore (where most traffic comes from - 60%)
module "database" {
  source = "./modules/database"

  providers = {
    aws = aws.singapore
  }

  region                = var.regions.singapore
  project_name          = var.project_name
  environment           = var.environment
  db_username           = var.db_username
  db_password           = random_password.db_password.result
  public_subnet_ids     = module.singapore_network.database_subnets # Using database subnets (private)
  rds_security_group_id = module.singapore_rds_sg.security_group_id
  random_suffix         = random_id.suffix.hex

  tags = var.common_tags
}

# Ireland Read Replica (30% of traffic)
module "ireland_database_replica" {
  source = "./modules/database"

  providers = {
    aws = aws.ireland
  }

  region                = var.regions.ireland
  project_name          = var.project_name
  environment           = var.environment
  db_username           = var.db_username
  db_password           = random_password.db_password.result
  public_subnet_ids     = module.ireland_network.database_subnets # Using database subnets (private)
  rds_security_group_id = module.ireland_rds_sg.security_group_id
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

  project_name        = var.project_name
  random_suffix       = random_id.suffix.hex
  environment         = var.environment
  db_username         = var.db_username
  db_password         = random_password.db_password.result
  db_endpoint         = module.database.db_endpoint
  ireland_db_endpoint = module.ireland_database_replica.db_endpoint
  wp_admin_password   = random_password.wp_admin_password.result

  tags = var.common_tags
}

# Singapore Compute
module "singapore_compute" {
  source = "./modules/compute"

  providers = {
    aws = aws.singapore
  }

  region                    = var.regions.singapore
  project_name              = var.project_name
  environment               = var.environment
  vpc_id                    = module.singapore_network.vpc_id
  private_subnets           = module.singapore_network.private_subnets
  public_subnets            = module.singapore_network.public_subnets
  alb_security_group_id     = module.singapore_alb_sg.security_group_id
  ec2_security_group_id     = module.singapore_ec2_sg.security_group_id
  ec2_instance_profile_name = module.singapore_ec2_sg.ec2_instance_profile_name
  instance_type             = var.instance_type
  min_size                  = var.min_size
  max_size                  = var.max_size
  desired_capacity          = var.desired_capacity
  s3_bucket_name            = module.data.s3_bucket_name
  db_endpoint               = module.database.db_endpoint
  parameter_store_prefix    = "/${var.project_name}/${var.environment}"

  # User data template variables
  user_data_template_vars = {
    region                    = var.regions.singapore
    db_region                 = var.regions.singapore
    project_name              = var.project_name
    environment               = var.environment
    db_endpoint_param         = module.data.singapore_db_endpoint_param
    db_username_param         = module.data.singapore_db_username_param
    db_password_param         = module.data.singapore_db_password_param
    s3_bucket_param           = module.data.s3_bucket_param
    primary_db_endpoint_param = module.data.singapore_db_endpoint_param
    admin_email               = var.admin_email
        distribution_id           = aws_ssm_parameter.cloudfront_distribution_id.name
  }

  tags = var.common_tags
}

# Ireland Compute
module "ireland_compute" {
  source = "./modules/compute"

  providers = {
    aws = aws.ireland
  }

  region                    = var.regions.ireland
  project_name              = var.project_name
  environment               = var.environment
  vpc_id                    = module.ireland_network.vpc_id
  private_subnets           = module.ireland_network.private_subnets
  public_subnets            = module.ireland_network.public_subnets
  alb_security_group_id     = module.ireland_alb_sg.security_group_id
  ec2_security_group_id     = module.ireland_ec2_sg.security_group_id
  ec2_instance_profile_name = module.ireland_ec2_sg.ec2_instance_profile_name
  instance_type             = var.instance_type
  min_size                  = var.min_size
  max_size                  = var.max_size
  desired_capacity          = var.desired_capacity
  s3_bucket_name            = module.data.s3_bucket_name
  db_endpoint               = module.database.db_endpoint
  parameter_store_prefix    = "/${var.project_name}/${var.environment}"

  # User data template variables
  user_data_template_vars = {
    region                    = var.regions.ireland
    db_region                 = var.regions.ireland
    project_name              = var.project_name
    environment               = var.environment
    db_endpoint_param         = module.data.ireland_db_endpoint_param
    db_username_param         = module.data.ireland_db_username_param
    db_password_param         = module.data.ireland_db_password_param
    s3_bucket_param           = module.data.s3_bucket_param
    primary_db_endpoint_param = module.data.singapore_db_endpoint_param
    admin_email               = var.admin_email
    distribution_id           = aws_ssm_parameter.cloudfront_distribution_id_ireland.name
  }

  tags = var.common_tags
}
