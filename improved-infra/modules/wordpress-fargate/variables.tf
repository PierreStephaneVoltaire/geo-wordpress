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

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for ECS tasks"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for ALB"
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "Security group ID for ALB"
  type        = string
}

variable "ecs_security_group_id" {
  description = "Security group ID for ECS tasks"
  type        = string
}

variable "redis_security_group_id" {
  description = "Security group ID for Redis"
  type        = string
}

variable "elasticache_subnet_group_name" {
  description = "ElastiCache subnet group name"
  type        = string
}

variable "s3_bucket_name" {
  description = "S3 bucket name for media uploads"
  type        = string
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "wordpress"
}

variable "db_primary_endpoint" {
  description = "Primary database endpoint"
  type        = string
  default     = ""
}

variable "db_replica_endpoint" {
  description = "Replica database endpoint"
  type        = string
  default     = ""
}

variable "fargate_cpu" {
  description = "Fargate CPU units"
  type        = number
  default     = 256
}

variable "fargate_memory" {
  description = "Fargate memory in MB"
  type        = number
  default     = 512
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}