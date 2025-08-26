output "primary_bucket_name" {
  description = "Primary S3 bucket name"
  value       = aws_s3_bucket.wordpress_media.id
}

output "primary_bucket_arn" {
  description = "Primary S3 bucket ARN"
  value       = aws_s3_bucket.wordpress_media.arn
}

output "primary_bucket_domain" {
  description = "Primary S3 bucket domain name"
  value       = aws_s3_bucket.wordpress_media.bucket_domain_name
}

output "replica_bucket_names" {
  description = "Replica S3 bucket names by region"
  value = {
    for region, bucket in aws_s3_bucket.wordpress_media_replica :
    region => bucket.id
  }
}

output "replica_bucket_arns" {
  description = "Replica S3 bucket ARNs by region"
  value = {
    for region, bucket in aws_s3_bucket.wordpress_media_replica :
    region => bucket.arn
  }
}