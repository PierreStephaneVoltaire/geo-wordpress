terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0"
    }
  }
}

# Local variables
locals {
  parameter_prefix = "/${var.project_name}/${var.environment}"
  primary_region   = [for k, v in var.regions : k if v.is_primary == true][0]
}

# Database credentials
resource "aws_ssm_parameter" "db_username" {
  name  = "${local.parameter_prefix}/database/username"
  type  = "String"
  value = var.db_username

  tags = merge(var.tags, {
    Name = "${var.project_name}-db-username"
  })
}

resource "aws_ssm_parameter" "db_password" {
  name  = "${local.parameter_prefix}/database/password"
  type  = "SecureString"
  value = var.db_password

  tags = merge(var.tags, {
    Name = "${var.project_name}-db-password"
  })
}

# WordPress admin credentials
resource "aws_ssm_parameter" "wp_admin_email" {
  name  = "${local.parameter_prefix}/wordpress/admin_email"
  type  = "String"
  value = var.admin_email

  tags = merge(var.tags, {
    Name = "${var.project_name}-wp-admin-email"
  })
}

resource "aws_ssm_parameter" "wp_admin_password" {
  name  = "${local.parameter_prefix}/wordpress/admin_password"
  type  = "SecureString"
  value = var.wp_admin_password

  tags = merge(var.tags, {
    Name = "${var.project_name}-wp-admin-password"
  })
}

# S3 bucket configuration
resource "aws_ssm_parameter" "s3_bucket_name" {
  name  = "${local.parameter_prefix}/s3/bucket_name"
  type  = "String"
  value = var.s3_bucket_name

  tags = merge(var.tags, {
    Name = "${var.project_name}-s3-bucket"
  })
}

# WordPress Security Keys and Salts
resource "random_password" "auth_key" {
  length  = 64
  special = true
}

resource "random_password" "secure_auth_key" {
  length  = 64
  special = true
}

resource "random_password" "logged_in_key" {
  length  = 64
  special = true
}

resource "random_password" "nonce_key" {
  length  = 64
  special = true
}

resource "random_password" "auth_salt" {
  length  = 64
  special = true
}

resource "random_password" "secure_auth_salt" {
  length  = 64
  special = true
}

resource "random_password" "logged_in_salt" {
  length  = 64
  special = true
}

resource "random_password" "nonce_salt" {
  length  = 64
  special = true
}

# WordPress security configuration
resource "aws_ssm_parameter" "wp_auth_key" {
  name  = "${local.parameter_prefix}/wordpress/auth_key"
  type  = "SecureString"
  value = random_password.auth_key.result

  tags = merge(var.tags, {
    Name = "${var.project_name}-wp-auth-key"
  })
}

resource "aws_ssm_parameter" "wp_secure_auth_key" {
  name  = "${local.parameter_prefix}/wordpress/secure_auth_key"
  type  = "SecureString"
  value = random_password.secure_auth_key.result

  tags = merge(var.tags, {
    Name = "${var.project_name}-wp-secure-auth-key"
  })
}

resource "aws_ssm_parameter" "wp_logged_in_key" {
  name  = "${local.parameter_prefix}/wordpress/logged_in_key"
  type  = "SecureString"
  value = random_password.logged_in_key.result

  tags = merge(var.tags, {
    Name = "${var.project_name}-wp-logged-in-key"
  })
}

resource "aws_ssm_parameter" "wp_nonce_key" {
  name  = "${local.parameter_prefix}/wordpress/nonce_key"
  type  = "SecureString"
  value = random_password.nonce_key.result

  tags = merge(var.tags, {
    Name = "${var.project_name}-wp-nonce-key"
  })
}

resource "aws_ssm_parameter" "wp_auth_salt" {
  name  = "${local.parameter_prefix}/wordpress/auth_salt"
  type  = "SecureString"
  value = random_password.auth_salt.result

  tags = merge(var.tags, {
    Name = "${var.project_name}-wp-auth-salt"
  })
}

resource "aws_ssm_parameter" "wp_secure_auth_salt" {
  name  = "${local.parameter_prefix}/wordpress/secure_auth_salt"
  type  = "SecureString"
  value = random_password.secure_auth_salt.result

  tags = merge(var.tags, {
    Name = "${var.project_name}-wp-secure-auth-salt"
  })
}

resource "aws_ssm_parameter" "wp_logged_in_salt" {
  name  = "${local.parameter_prefix}/wordpress/logged_in_salt"
  type  = "SecureString"
  value = random_password.logged_in_salt.result

  tags = merge(var.tags, {
    Name = "${var.project_name}-wp-logged-in-salt"
  })
}

resource "aws_ssm_parameter" "wp_nonce_salt" {
  name  = "${local.parameter_prefix}/wordpress/nonce_salt"
  type  = "SecureString"
  value = random_password.nonce_salt.result

  tags = merge(var.tags, {
    Name = "${var.project_name}-wp-nonce-salt"
  })
}

# Database endpoints - Primary
resource "aws_ssm_parameter" "db_endpoint_primary" {
  name  = "${local.parameter_prefix}/database/endpoint/primary"
  type  = "String"
  value = var.db_primary_endpoint != "" ? var.db_primary_endpoint : "placeholder"

  tags = merge(var.tags, {
    Name = "${var.project_name}-db-endpoint-primary"
  })

  lifecycle {
    ignore_changes = [value]
  }
}

# Database endpoints - Secondary regions
resource "aws_ssm_parameter" "db_endpoint_secondary" {
  for_each = {
    for k, v in var.regions : k => v if v.is_primary == false
  }

  name  = "${local.parameter_prefix}/database/endpoint/${each.key}"
  type  = "String"
  value = lookup(var.db_secondary_endpoints, each.key, "placeholder")

  tags = merge(var.tags, {
    Name = "${var.project_name}-db-endpoint-${each.key}"
  })

  lifecycle {
    ignore_changes = [value]
  }
}

# CloudFront distribution domain
resource "aws_ssm_parameter" "cloudfront_domain" {
  name  = "${local.parameter_prefix}/cloudfront/distribution_domain_name"
  type  = "String"
  value = var.cloudfront_domain != "" ? var.cloudfront_domain : "placeholder"

  tags = merge(var.tags, {
    Name = "${var.project_name}-cloudfront-domain"
  })

  lifecycle {
    ignore_changes = [value]
  }
}