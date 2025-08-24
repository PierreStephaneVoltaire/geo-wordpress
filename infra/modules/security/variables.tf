variable "vpc_id" {
  description = "VPC ID where security groups will be created"
  type        = string

}
variable "source_security_group_ids" {
  description = "List of security group IDs to allow access from"
  type        = list(string)
  default     = []
}

variable "create_ec2_role" {
  description = "Whether to create EC2 IAM role and policies"
  type        = bool
  default     = false
}

variable "s3_bucket_name" {
  description = "S3 bucket name for IAM policies"
  type        = string
  default     = ""
}

variable "parameter_store_prefix" {
  description = "Parameter store prefix for IAM policies"
  type        = string
  default     = ""
}



variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "allowed_cidr_blocks" {
  description = "List of CIDR blocks allowed to access resources"
  type        = list(string)
  default     = []
}

variable "security_group_type" {
  description = "Type of security group to create (alb, ec2, or rds)"
  type        = string
  validation {
    condition     = contains(["alb", "ec2", "rds"], var.security_group_type)
    error_message = "Security group type must be one of: alb, ec2, rds."
  }
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
}
