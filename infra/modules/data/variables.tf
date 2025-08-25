variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "random_suffix" {
  description = "Random suffix for unique naming"
  type        = string
}



variable "environment" {
  description = "Environment name for parameter store"
  type        = string
  default     = ""
}

variable "db_password" {
  description = "Database password for parameter store"
  type        = string
  default     = ""
  sensitive   = true
}

variable "db_username" {
  description = "Database username for parameter store"
  type        = string
  default     = ""
}

variable "db_endpoint" {
  description = "Primary database endpoint for parameter store"
  type        = string
  default     = ""
}

variable "secondary_db_endpoints" {
  description = "Map of secondary region database endpoints for parameter store"
  type        = map(string)
  default     = {}
}

variable "regions_config" {
  description = "Configuration for all deployed regions"
  type = map(object({
    is_primary = bool
    aws_region = string
  }))
  default = {}
}

variable "wp_admin_password" {
  description = "WordPress admin password for parameter store"
  type        = string
  default     = ""
  sensitive   = true
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
}
