output "alb_dns_name" {
  description = "DNS name of the load balancer"
  value       = aws_lb.wordpress.dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the load balancer"
  value       = aws_lb.wordpress.zone_id
}

output "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.wordpress.name
}
