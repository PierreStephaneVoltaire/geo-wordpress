variable "region" {
  description = "AWS region"
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

variable "vpc_id" {
  description = "VPC ID for resources"
  type        = string
}

variable "private_subnets" {
  description = "List of private subnet IDs for ASG (not used - keeping for compatibility)"
  type        = list(string)
  default     = []
}

variable "public_subnets" {
  description = "List of public subnet IDs for ALB"
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "Security group ID for ALB"
  type        = string
}

variable "ec2_security_group_id" {
  description = "Security group ID for EC2 instances"
  type        = string
}

variable "ec2_instance_profile_name" {
  description = "Name of the IAM instance profile for EC2"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "min_size" {
  description = "Minimum number of instances in ASG"
  type        = number
}

variable "max_size" {
  description = "Maximum number of instances in ASG"
  type        = number
}

variable "desired_capacity" {
  description = "Desired number of instances in ASG"
  type        = number
}

variable "s3_bucket_name" {
  description = "S3 bucket name for WordPress uploads"
  type        = string
}

variable "db_endpoint" {
  description = "Database endpoint"
  type        = string
}

variable "parameter_store_prefix" {
  description = "Parameter store prefix for database credentials"
  type        = string
}

variable "user_data_template_vars" {
  description = "Variables for user data template"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
}
