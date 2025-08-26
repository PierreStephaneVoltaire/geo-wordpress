# Terraform backend configuration
# Note: Update the bucket name and region as needed for your environment
terraform {
  backend "s3" {
    bucket  = "pierre-tf-state"
    key     = "improved-infra/terraform.tfstate"
    region  = "ca-central-1"
    encrypt = true
    
    # S3 native state locking (no DynamoDB required)
    use_lockfile = true
  }
}