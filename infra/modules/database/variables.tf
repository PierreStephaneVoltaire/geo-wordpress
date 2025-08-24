variable "region" {
  description = "AWS region for the database"
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

variable "db_username" {
  description = "Database master username"
  type        = string
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for database subnet group"
  type        = list(string)
}

variable "rds_security_group_id" {
  description = "Security group ID for RDS"
  type        = string
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
}

variable "create_read_replica" {
  description = "Whether to create a read replica instead of primary"
  type        = bool
  default     = false
}

variable "source_db_identifier" {
  description = "Source database identifier for read replica"
  type        = string
  default     = ""
}

variable "source_db_arn" {
  description = "Source database ARN for cross-region read replica"
  type        = string
  default     = ""
}

variable "random_suffix" {
  description = "Random suffix for unique naming"
  type        = string
}
