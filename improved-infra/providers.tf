# Single AWS provider with default region
# AWS Provider 6.0+ supports region parameter on individual resources
provider "aws" {
  region = "us-east-1" # Default region for global services like CloudFront
  
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}