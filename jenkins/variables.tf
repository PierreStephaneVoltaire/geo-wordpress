# variables.tf
variable "region" {
  description = "AWS region"
  type        = string
  default     = "ca-central-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Environment = "DevOps"
    Purpose     = "Jenkins-CICD"
    ManagedBy   = "Terraform"
  }
}

variable "vpc_name" {
  description = "Name for the VPC"
  type        = string
  default     = "jenkins-vpc"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/24"
}

variable "enable_nat_gateway" {
  description = "Whether to create a NAT gateway"
  type        = bool
  default     = false
}

variable "enable_dns_hostnames" {
  description = "Whether to enable DNS hostnames"
  type        = bool
  default     = true
}

variable "azs" {
  description = "List of AZs to use (single AZ for small VPC)"
  type        = list(string)
  default     = ["ca-central-1a"]
}

variable "public_subnets" {
  description = "List of public subnet CIDRs"
  type        = list(string)
  default     = ["10.0.0.0/28"]
}

variable "allowed_ingress_cidr" {
  description = "CIDR allowed to access Jenkins web UI"
  type        = string
  default     = "0.0.0.0/0"
}