variable "geo_regions" {
  description = "Geographic region configuration for deployment"
  type = object({
    primary   = string
    secondary = list(string)
    all       = map(string)
    vpc_cidrs = map(string)
  })
  default = {
    primary   = "singapore"
    secondary = ["ireland"]
    all = {
      singapore = "ap-southeast-1"
      ireland   = "eu-west-1"
    }
    vpc_cidrs = {
      singapore = "10.0.0.0/16"
      ireland   = "10.1.0.0/16"
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

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "min_size" {
  description = "Minimum number of instances in ASG"
  type        = number
  default     = 0
}

variable "max_size" {
  description = "Maximum number of instances in ASG"
  type        = number
  default     = 4
}

variable "desired_capacity" {
  description = "Desired number of instances in ASG"
  type        = number
  default     = 0
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Project     = "WordPress-Geo"
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}

variable "admin_email" {
  description = "WordPress admin email address"
  type        = string
  default     = "pvoltaire96@gmail.com"
}
