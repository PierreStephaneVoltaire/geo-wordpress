variable "region" {
  description = "AWS region"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}




variable "create_vpc_peering" {
  description = "Whether to create VPC peering connection"
  type        = bool
  default     = false
}

variable "accept_vpc_peering" {
  description = "Whether to accept VPC peering connection"
  type        = bool
  default     = false
}

variable "create_peering_routes" {
  description = "Whether to create peering routes"
  type        = bool
  default     = false
}

variable "peer_vpc_id" {
  description = "Peer VPC ID for peering"
  type        = string
  default     = ""
}

variable "peer_region" {
  description = "Peer region for peering"
  type        = string
  default     = ""
}

variable "peer_vpc_cidr" {
  description = "Peer VPC CIDR for routing"
  type        = string
  default     = ""
}

variable "peering_connection_id" {
  description = "Peering connection ID to accept"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
}
