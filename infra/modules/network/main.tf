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



resource "aws_vpc_peering_connection" "singapore_to_ireland" {
  count       = var.create_vpc_peering ? 1 : 0
  vpc_id      = module.vpc.vpc_id
  peer_vpc_id = var.peer_vpc_id
  peer_region = var.peer_region
  auto_accept = false
}

resource "aws_vpc_peering_connection_accepter" "accept_peering" {
  count                     = var.accept_vpc_peering ? 1 : 0
  vpc_peering_connection_id = var.peering_connection_id
  auto_accept               = true
}

resource "aws_route" "to_peer_vpc" {
  count                     = var.create_peering_routes ? 1 : 0
  route_table_id            = module.vpc.public_route_table_ids[0]
  destination_cidr_block    = var.peer_vpc_cidr
  vpc_peering_connection_id = var.create_vpc_peering ? aws_vpc_peering_connection.singapore_to_ireland[0].id : var.peering_connection_id
}
