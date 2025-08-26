output "distribution_id" {
  description = "CloudFront distribution ID"
  value       = aws_cloudfront_distribution.wordpress.id
}

output "distribution_domain_name" {
  description = "CloudFront distribution domain name"
  value       = aws_cloudfront_distribution.wordpress.domain_name
}

output "distribution_arn" {
  description = "CloudFront distribution ARN"
  value       = aws_cloudfront_distribution.wordpress.arn
}

output "lambda_edge_function_arn" {
  description = "Lambda@Edge function ARN"
  value       = aws_lambda_function.geo_router.qualified_arn
}