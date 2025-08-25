terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = ">= 6.0.0"
      configuration_aliases = [aws.us_east_1]
    }
  }
}


data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${var.project_name}-${var.environment}-${var.region}"
  cidr = var.vpc_cidr

  azs = slice(data.aws_availability_zones.available.names, 0, 2)

  public_subnets = [
    cidrsubnet(var.vpc_cidr, 8, 101),
    cidrsubnet(var.vpc_cidr, 8, 102)
  ]
  private_subnets = [
    cidrsubnet(var.vpc_cidr, 8, 1),
    cidrsubnet(var.vpc_cidr, 8, 2)
  ]

  database_subnets = [
    cidrsubnet(var.vpc_cidr, 8, 21),
    cidrsubnet(var.vpc_cidr, 8, 22)
  ]

  enable_nat_gateway   = false
  enable_vpn_gateway   = false
  enable_dns_hostnames = true
  enable_dns_support   = true

  create_database_subnet_group = true
}

# VPC Peering connections to secondary regions (only for primary region)
resource "aws_vpc_peering_connection" "to_secondary" {
  for_each = var.peer_vpc_ids

  vpc_id      = module.vpc.vpc_id
  peer_vpc_id = each.value
  peer_region = each.key
  auto_accept = false

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-peering-to-${each.key}"
  })
}
