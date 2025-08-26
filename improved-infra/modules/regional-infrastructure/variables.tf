variable "region_name" {
  description = "Name of the region (e.g., singapore, ireland)"
  type        = string
}

variable "region_config" {
  description = "Region configuration object"
  type = object({
    region     = string
    vpc_cidr   = string
    is_primary = bool
    fargate = object({
      min_capacity     = number
      max_capacity     = number
      desired_capacity = number
    })
  })
}

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

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}