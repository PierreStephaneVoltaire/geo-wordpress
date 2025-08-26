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

variable "db_username" {
  description = "Database master username"
  type        = string
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "regional_infrastructure" {
  description = "Regional infrastructure outputs"
  type = map(object({
    db_subnet_group_name   = string
    rds_security_group_id  = string
  }))
}

variable "aurora_instance_class" {
  description = "Aurora instance class"
  type        = string
  default     = "db.t4g.medium"
}

variable "aurora_instance_count" {
  description = "Number of Aurora instances per cluster"
  type        = number
  default     = 1
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}