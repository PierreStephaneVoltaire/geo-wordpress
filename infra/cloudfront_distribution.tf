
resource "aws_iam_role" "lambda_edge_role" {
  provider = aws.us_east_1
  name     = "${var.project_name}-lambda-edge-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = [
            "lambda.amazonaws.com",
            "edgelambda.amazonaws.com"
          ]
        }
      }
    ]
  })

  tags = var.common_tags
}

resource "aws_iam_role_policy_attachment" "lambda_edge_policy" {
  provider   = aws.us_east_1
  role       = aws_iam_role.lambda_edge_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Create the Lambda function code
data "archive_file" "geo_router_zip" {
  type        = "zip"
  output_path = "lambda/geo_router.zip"

  source {
    content = templatefile("${path.module}/lambda/geo_router.py", {
      ireland_alb_dns   = module.ireland_compute.alb_dns_name
      singapore_alb_dns = module.singapore_compute.alb_dns_name
    })
    filename = "index.py"
  }
}

# Lambda@Edge function for geo-based routing
resource "aws_lambda_function" "geo_router" {
  provider = aws.us_east_1

  filename         = "lambda/geo_router.zip"
  function_name    = "${var.project_name}-geo-router"
  role             = aws_iam_role.lambda_edge_role.arn
  handler          = "index.handler"
  runtime          = "python3.9"
  timeout          = 5
  publish          = true
  source_code_hash = data.archive_file.geo_router_zip.output_base64sha256
  depends_on       = [data.archive_file.geo_router_zip]

  tags = var.common_tags
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "wordpress" {
  provider = aws.us_east_1

  comment             = "${var.project_name} WordPress Distribution"
  default_root_object = "index.php"
  enabled             = true
  is_ipv6_enabled     = true
  price_class         = "PriceClass_100"

  # Singapore ALB Origin (Primary)
  origin {
    domain_name = module.singapore_compute.alb_dns_name
    origin_id   = "singapore-alb"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # Ireland ALB Origin (Secondary)
  origin {
    domain_name = module.ireland_compute.alb_dns_name
    origin_id   = "ireland-alb"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # Default cache behavior with Lambda@Edge
  default_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "singapore-alb"
    compress               = true
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = true
      headers      = ["Host", "Origin", "Referer", "Accept", "Accept-Language", "Accept-Encoding", "CloudFront-Viewer-Country"]

      cookies {
        forward = "all"
      }
    }

    # Lambda@Edge function for viewer request
    lambda_function_association {
      event_type   = "viewer-request"
      lambda_arn   = aws_lambda_function.geo_router.qualified_arn
      include_body = false
    }

    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0
  }

  # Additional cache behavior for static assets
  ordered_cache_behavior {
    path_pattern           = "/wp-content/*"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "singapore-alb"
    compress               = true
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      headers      = ["Origin"]

      cookies {
        forward = "none"
      }
    }

    min_ttl     = 86400
    default_ttl = 604800
    max_ttl     = 31536000
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = var.common_tags
}

resource "aws_ssm_parameter" "cloudfront_distribution_id" {
  provider  = aws.singapore
  name      = "/${var.project_name}/${var.environment}/cloudfront/distribution_id"
  type      = "String"
  value     = aws_cloudfront_distribution.wordpress.id
  overwrite = true

}

resource "aws_ssm_parameter" "cloudfront_distribution_id_ireland" {
  provider  = aws.ireland
  name      = "/${var.project_name}/${var.environment}/cloudfront/distribution_id"
  type      = "String"
  value     = aws_cloudfront_distribution.wordpress.id
  overwrite = true

}