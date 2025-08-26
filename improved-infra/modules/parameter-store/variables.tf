variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "regions" {
  description = "Regional configuration map"
  type = map(object({
    region     = string
    vpc_cidr   = string
    is_primary = bool
    fargate = object({
      min_capacity     = number
      max_capacity     = number
      desired_capacity = number
    })
  }))
}

variable "db_username" {
  description = "Database master username"
  type        = string
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
}

variable "wp_admin_password" {
  description = "WordPress admin password"
  type        = string
  sensitive   = true
}

variable "admin_email" {
  description = "WordPress admin email address"
  type        = string
}

variable "s3_bucket_name" {
  description = "S3 bucket name for media uploads"
  type        = string
}

variable "db_primary_endpoint" {
  description = "Primary database endpoint"
  type        = string
  default     = ""
}

variable "db_secondary_endpoints" {
  description = "Secondary database endpoints by region"
  type        = map(string)
  default     = {}
}

variable "cloudfront_domain" {
  description = "CloudFront distribution domain name"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}