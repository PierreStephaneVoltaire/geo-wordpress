# Singapore provider
provider "aws" {
  alias  = "singapore"
  region = var.geo_regions.all.singapore
  default_tags {
    tags = var.common_tags
  }
}

# Ireland provider
provider "aws" {
  alias  = "ireland"
  region = var.geo_regions.all.ireland
  default_tags {
    tags = var.common_tags
  }
}

# Default provider (Primary region)
provider "aws" {
  region = var.geo_regions.all[var.geo_regions.primary]
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
