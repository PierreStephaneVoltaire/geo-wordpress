output "instance_id" {
  description = "ID of the Jenkins EC2 instance"
  value       = aws_instance.jenkins.id
}

output "instance_private_ip" {
  description = "Private IP of the Jenkins EC2 instance"
  value       = aws_instance.jenkins.private_ip
}

output "instance_public_ip" {
  description = "Public IP of the Jenkins EC2 instance"
  value       = aws_instance.jenkins.public_ip
}

output "devops_assume_role_arn" {
  description = "ARN of the DevOps assume role for SSM access"
  value       = aws_iam_role.devops_assume_role.arn
}

output "ssm_connect_command" {
  description = "Command to connect to the instance via SSM"
  value       = "aws ssm start-session --target ${aws_instance.jenkins.id}"
}

output "assume_role_command" {
  description = "Command to assume the DevOps role"
  value       = "aws sts assume-role --role-arn ${aws_iam_role.devops_assume_role.arn} --role-session-name devops-session --external-id devops-access-${data.aws_caller_identity.current.account_id}"
}

output "jenkins_url" {
  description = "URL to access Jenkins"
  value       = "http://${aws_instance.jenkins.public_ip}:8080"
}