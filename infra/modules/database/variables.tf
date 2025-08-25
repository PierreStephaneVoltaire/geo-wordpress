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

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "wordpress"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Initial allocated storage for RDS in GB"
  type        = number
  default     = 20
}

variable "db_max_allocated_storage" {
  description = "Maximum allocated storage for RDS autoscaling in GB"
  type        = number
  default     = 100
}

variable "db_engine_version" {
  description = "MariaDB engine version"
  type        = string
  default     = "10.11.8"
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
