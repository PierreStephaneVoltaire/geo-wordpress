variable "regions" {
  description = "Regional configuration map with Fargate capacity settings"
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
  default = {
    singapore = {
      region     = "ap-southeast-1"
      vpc_cidr   = "10.0.0.0/16"
      is_primary = true
      fargate = {
        min_capacity     = 1
        max_capacity     = 3   # Reduced max for cost control
        desired_capacity = 1   # Start with minimal capacity for <400 requests/month
      }
    }
    ireland = {
      region     = "eu-west-1"
      vpc_cidr   = "10.1.0.0/16"
      is_primary = false
      fargate = {
        min_capacity     = 1
        max_capacity     = 3   # Reduced max for cost control  
        desired_capacity = 1   # Start with minimal capacity
      }
    }
  }
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "wordpress-geo"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "wpuser"
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "wordpress"
}

variable "admin_email" {
  description = "WordPress admin email address"
  type        = string
  default     = "admin@example.com"
}

variable "geoblocking_countries" {
  description = <<-EOT
    List of country codes to block access from CloudFront distribution.
    Uses ISO 3166-1 alpha-2 country codes. Leave empty to allow all countries.
  EOT
  type        = list(string)
  default     = []
}

# Aurora instance configuration
variable "aurora_instance_class" {
  description = "Aurora instance class - use smallest for low traffic"
  type        = string
  default     = "db.t4g.medium"  # Smallest Aurora instance for cost optimization
}

variable "aurora_instance_count" {
  description = "Number of Aurora instances per cluster"
  type        = number
  default     = 1  # Single instance for cost optimization with <400 requests/month
}

# Fargate task configuration for cost optimization
variable "fargate_cpu" {
  description = "Fargate CPU units (256 = 0.25 vCPU)"
  type        = number
  default     = 256  # 0.25 vCPU - minimal for low traffic
}

variable "fargate_memory" {
  description = "Fargate memory in MB"
  type        = number
  default     = 512  # 0.5 GB RAM - minimal for WordPress
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Project     = "WordPress-Geo-V2"
    Environment = "Production"
    ManagedBy   = "Terraform"
    Architecture = "Fargate-Global"
    CostProfile = "Minimal"
  }
}