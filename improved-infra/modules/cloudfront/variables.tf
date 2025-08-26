variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "random_suffix" {
  description = "Random suffix for unique resource naming"
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

variable "alb_origins" {
  description = "ALB DNS names by region for CloudFront origins"
  type        = map(string)
}

variable "s3_bucket_domain" {
  description = "S3 bucket domain name for static assets"
  type        = string
}

variable "geoblocking_countries" {
  description = "List of country codes to block"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}