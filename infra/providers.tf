# Singapore provider
provider "aws" {
  alias  = "singapore"
  region = var.regions.singapore
  default_tags {
    tags = var.common_tags
  }
}

# Ireland provider
provider "aws" {
  alias  = "ireland"
  region = var.regions.ireland
  default_tags {
    tags = var.common_tags
  }
}

# Default provider (Singapore)
provider "aws" {
  region = var.regions.singapore
  default_tags {
    tags = var.common_tags
  }
}

# US East 1 provider for Lambda@Edge and CloudFront
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
  default_tags {
    tags = var.common_tags
  }
}
