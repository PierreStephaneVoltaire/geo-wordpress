output "ecs_cluster_id" {
  description = "ECS cluster ID"
  value       = aws_ecs_cluster.wordpress.id
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.wordpress.name
}

output "ecs_service_id" {
  description = "ECS service ID"
  value       = aws_ecs_service.wordpress.id
}

output "ecs_service_name" {
  description = "ECS service name"
  value       = aws_ecs_service.wordpress.name
}

output "alb_id" {
  description = "Application Load Balancer ID"
  value       = aws_lb.wordpress.id
}

output "alb_arn" {
  description = "Application Load Balancer ARN"
  value       = aws_lb.wordpress.arn
}

output "alb_dns_name" {
  description = "Application Load Balancer DNS name"
  value       = aws_lb.wordpress.dns_name
}

output "alb_zone_id" {
  description = "Application Load Balancer zone ID"
  value       = aws_lb.wordpress.zone_id
}

output "target_group_arn" {
  description = "Target group ARN"
  value       = aws_lb_target_group.wordpress.arn
}

output "redis_primary_endpoint" {
  description = "Redis primary endpoint"
  value       = aws_elasticache_replication_group.redis.primary_endpoint_address
}

output "redis_reader_endpoint" {
  description = "Redis reader endpoint"
  value       = aws_elasticache_replication_group.redis.reader_endpoint_address
}