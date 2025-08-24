variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "random_suffix" {
  description = "Random suffix for unique naming"
  type        = string
}

variable "create_parameters" {
  description = "Whether to create parameter store entries"
  type        = bool
  default     = false
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
  description = "Database endpoint for parameter store"
  type        = string
  default     = ""
}

variable "ireland_db_endpoint" {
  description = "Ireland database endpoint for parameter store"
  type        = string
  default     = ""
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
