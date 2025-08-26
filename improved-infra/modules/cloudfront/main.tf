terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0"
    }
  }
}

# Lambda@Edge function for geo-routing
data "archive_file" "geo_router_zip" {
  type        = "zip"
  output_path = "${path.module}/geo_router.zip"
  source {
    content = templatefile("${path.module}/geo_router.py", {
      regions = var.regions
    })
    filename = "lambda_function.py"
  }
}

# IAM role for Lambda@Edge
resource "aws_iam_role" "lambda_edge" {
  name = "${var.project_name}-lambda-edge-${var.random_suffix}"

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

  tags = var.tags
}

# IAM policy for Lambda@Edge
resource "aws_iam_role_policy_attachment" "lambda_edge" {
  role       = aws_iam_role.lambda_edge.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Lambda@Edge function
resource "aws_lambda_function" "geo_router" {
  region = "us-east-1" # Lambda@Edge must be in us-east-1
  
  filename         = data.archive_file.geo_router_zip.output_path
  function_name    = "${var.project_name}-geo-router-${var.random_suffix}"
  role            = aws_iam_role.lambda_edge.arn
  handler         = "lambda_function.lambda_handler"
  runtime         = "python3.12"
  timeout         = 5
  
  source_code_hash = data.archive_file.geo_router_zip.output_base64sha256
  
  publish = true

  tags = var.tags
}

# CloudFront Origin Access Control for S3
resource "aws_cloudfront_origin_access_control" "s3_oac" {
  name                              = "${var.project_name}-s3-oac-${var.random_suffix}"
  description                       = "OAC for S3 bucket access"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFront distribution
resource "aws_cloudfront_distribution" "wordpress" {
  comment             = "WordPress Global Distribution - ${var.project_name}"
  default_root_object = "index.html"
  enabled             = true
  is_ipv6_enabled     = true
  price_class         = "PriceClass_All"

  # S3 origin for static assets
  origin {
    domain_name              = var.s3_bucket_domain
    origin_access_control_id = aws_cloudfront_origin_access_control.s3_oac.id
    origin_id                = "S3-${var.project_name}-media"
    
    connection_attempts = 3
    connection_timeout  = 10
  }

  # ALB origins for each region
  dynamic "origin" {
    for_each = var.alb_origins
    content {
      domain_name = origin.value
      origin_id   = "ALB-${origin.key}"
      
      connection_attempts = 3
      connection_timeout  = 10
      
      custom_origin_config {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "http-only"
        origin_ssl_protocols   = ["TLSv1.2"]
      }
    }
  }

  # Default cache behavior for dynamic content (WordPress)
  default_cache_behavior {
    allowed_methods            = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods             = ["GET", "HEAD"]
    target_origin_id           = "ALB-${keys(var.alb_origins)[0]}" # Default to first region
    compress                   = true
    viewer_protocol_policy     = "redirect-to-https"
    cache_policy_id            = aws_cloudfront_cache_policy.wordpress_dynamic.id
    origin_request_policy_id   = aws_cloudfront_origin_request_policy.wordpress_dynamic.id

    lambda_function_association {
      event_type   = "origin-request"
      lambda_arn   = aws_lambda_function.geo_router.qualified_arn
      include_body = false
    }
  }

  # Cache behavior for static assets (S3)
  ordered_cache_behavior {
    path_pattern               = "/wp-content/uploads/*"
    allowed_methods            = ["GET", "HEAD", "OPTIONS"]
    cached_methods             = ["GET", "HEAD"]
    target_origin_id           = "S3-${var.project_name}-media"
    compress                   = true
    viewer_protocol_policy     = "redirect-to-https"
    cache_policy_id            = aws_cloudfront_cache_policy.wordpress_static.id
  }

  # Cache behavior for WordPress assets
  ordered_cache_behavior {
    path_pattern               = "/wp-content/*"
    allowed_methods            = ["GET", "HEAD", "OPTIONS"]
    cached_methods             = ["GET", "HEAD"]
    target_origin_id           = "ALB-${keys(var.alb_origins)[0]}"
    compress                   = true
    viewer_protocol_policy     = "redirect-to-https"
    cache_policy_id            = aws_cloudfront_cache_policy.wordpress_static.id
    
    lambda_function_association {
      event_type   = "origin-request"
      lambda_arn   = aws_lambda_function.geo_router.qualified_arn
      include_body = false
    }
  }

  # Geographic restrictions
  restrictions {
    geo_restriction {
      restriction_type = length(var.geoblocking_countries) > 0 ? "blacklist" : "none"
      locations        = var.geoblocking_countries
    }
  }

  # SSL certificate
  viewer_certificate {
    cloudfront_default_certificate = true
    minimum_protocol_version       = "TLSv1.2_2021"
  }

  tags = var.tags
}

# Cache policy for dynamic content
resource "aws_cloudfront_cache_policy" "wordpress_dynamic" {
  name        = "${var.project_name}-dynamic-${var.random_suffix}"
  comment     = "Cache policy for WordPress dynamic content"
  default_ttl = 0
  max_ttl     = 31536000
  min_ttl     = 0

  parameters_in_cache_key_and_forwarded_to_origin {
    enable_accept_encoding_brotli = true
    enable_accept_encoding_gzip   = true

    headers_config {
      header_behavior = "whitelist"
      headers {
        items = ["Host", "CloudFront-Viewer-Country"]
      }
    }

    query_strings_config {
      query_string_behavior = "all"
    }

    cookies_config {
      cookie_behavior = "all"
    }
  }
}

# Cache policy for static content
resource "aws_cloudfront_cache_policy" "wordpress_static" {
  name        = "${var.project_name}-static-${var.random_suffix}"
  comment     = "Cache policy for WordPress static assets"
  default_ttl = 86400
  max_ttl     = 31536000
  min_ttl     = 0

  parameters_in_cache_key_and_forwarded_to_origin {
    enable_accept_encoding_brotli = true
    enable_accept_encoding_gzip   = true

    headers_config {
      header_behavior = "none"
    }

    query_strings_config {
      query_string_behavior = "none"
    }

    cookies_config {
      cookie_behavior = "none"
    }
  }
}

# Origin request policy for dynamic content
resource "aws_cloudfront_origin_request_policy" "wordpress_dynamic" {
  name    = "${var.project_name}-dynamic-origin-${var.random_suffix}"
  comment = "Origin request policy for WordPress dynamic content"

  headers_config {
    header_behavior = "allViewer"
  }

  query_strings_config {
    query_string_behavior = "all"
  }

  cookies_config {
    cookie_behavior = "all"
  }
}