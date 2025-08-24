output "security_group_id" {
  description = "ID of the created security group"
  value = var.security_group_type == "alb" ? (
    length(aws_security_group.alb) > 0 ? aws_security_group.alb[0].id : null
    ) : var.security_group_type == "ec2" ? (
    length(aws_security_group.ec2) > 0 ? aws_security_group.ec2[0].id : null
    ) : var.security_group_type == "rds" ? (
    length(aws_security_group.rds) > 0 ? aws_security_group.rds[0].id : null
  ) : null
}

output "ec2_instance_profile_name" {
  description = "Name of the EC2 instance profile"
  value       = var.security_group_type == "ec2" && length(aws_iam_instance_profile.ec2_profile) > 0 ? aws_iam_instance_profile.ec2_profile[0].name : ""
}

output "ec2_role_arn" {
  description = "ARN of the EC2 IAM role"
  value       = var.security_group_type == "ec2" && length(aws_iam_role.ec2_role) > 0 ? aws_iam_role.ec2_role[0].arn : ""
}
