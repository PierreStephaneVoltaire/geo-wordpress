# Generalized Multi-Region Terraform Infrastructure

This Terraform configuration has been refactored to support a generalized multi-region deployment approach. The infrastructure can now be easily extended to support additional regions by modifying a single variable.

## Key Changes Made

### 1. Variable Structure
- **Old**: Separate `regions` and `vpc_cidrs` variables with hardcoded region names
- **New**: Single `geo_regions` object variable containing:
  - `primary`: The primary region name (string)
  - `secondary`: List of secondary region names (list of strings)
  - `all`: Map of region names to AWS region codes (map)
  - `vpc_cidrs`: Map of region names to VPC CIDR blocks (map)

### 2. Resource Organization
- **Networking**: Region-specific modules with conditional deployment
- **Security Groups**: Dynamic creation based on deployed regions
- **Compute**: Conditional deployment per region with appropriate provider assignment
- **Database**: Primary database in the primary region, read replicas in secondary regions
- **CloudFront**: Dynamic origins based on deployed regions

### 3. Provider Limitations Addressed
Due to Terraform's limitations with dynamic provider assignment, the current implementation:
- Uses explicit provider aliases for each supported region
- Employs conditional deployment (`count`) to deploy resources only in configured regions
- Creates local maps to uniformly reference modules across the infrastructure

## How to Add/Remove Regions

### Adding a New Region (e.g., "tokyo")

1. **Update the `geo_regions` variable in `variables.tf`**:
```hcl
default = {
  primary   = "singapore"
  secondary = ["ireland", "tokyo"]  # Add tokyo here
  all = {
    singapore = "ap-southeast-1"
    ireland   = "eu-west-1"
    tokyo     = "ap-northeast-1"    # Add tokyo mapping
  }
  vpc_cidrs = {
    singapore = "10.0.0.0/16"
    ireland   = "10.1.0.0/16"
    tokyo     = "10.2.0.0/16"      # Add tokyo CIDR
  }
}
```

2. **Add a provider in `providers.tf`**:
```hcl
provider "aws" {
  alias  = "tokyo"
  region = var.geo_regions.all.tokyo
  default_tags {
    tags = var.common_tags
  }
}
```

3. **Add region-specific modules** in `network.tf`:
```hcl
# Tokyo Network
module "tokyo_network" {
  count  = contains(keys(local.all_region_configs), "tokyo") ? 1 : 0
  source = "./modules/network"

  providers = {
    aws           = aws.tokyo
    aws.us_east_1 = aws.us_east_1
  }

  region       = local.all_region_configs["tokyo"].aws_region
  vpc_cidr     = local.all_region_configs["tokyo"].vpc_cidr
  project_name = var.project_name
  environment  = var.environment

  tags = var.common_tags
}
```

4. **Add security groups** and **compute modules** following the same pattern.

5. **Update local maps** to include the new region in the mappings.

### Removing a Region

1. Remove the region from the `geo_regions` variable
2. Remove the corresponding provider (optional, but recommended for cleanup)
3. Remove the region-specific modules
4. The conditional deployment (`count`) will automatically handle the removal

### Changing the Primary Region

1. Update the `primary` field in `geo_regions`
2. Move the previous primary region to the `secondary` list
3. Update provider assignments in the database module if needed

## Current Configuration

The default configuration deploys:
- **Primary Region**: Singapore (`ap-southeast-1`)
- **Secondary Regions**: Ireland (`eu-west-1`)

## Architecture Benefits

1. **Scalability**: Easy to add/remove regions
2. **Maintainability**: Single source of truth for region configuration
3. **Consistency**: Uniform resource naming and tagging across regions
4. **Flexibility**: Can easily change primary/secondary region assignments

## Important Notes and Limitations

### Provider Limitations
Due to Terraform's restrictions with dynamic provider assignment:
- **Providers must be explicitly defined** for each region in `providers.tf`
- **Module provider assignments** are hardcoded (e.g., `aws.singapore`, `aws.ireland`)
- **Data module limitation**: Secondary region SSM parameters are currently limited to Ireland provider
- **Manual updates required**: When adding new regions, you'll need to manually add corresponding modules and provider assignments

### Current Architecture Constraints
1. **Two-region limit**: The current implementation is optimized for Singapore (primary) and Ireland (secondary)
2. **Data module**: Partially generalized - primary region is fully dynamic, but secondary regions use hardcoded Ireland provider
3. **Network module**: Contains hardcoded VPC peering references between Singapore and Ireland
4. **Maximum scalability**: With current provider approach, you can add regions but with manual module definitions

### Fully Generalized Components
✅ **Variables**: Completely generalized with `geo_regions` structure  
✅ **Local calculations**: Dynamic region configuration management  
✅ **Compute modules**: Conditional deployment based on configured regions  
✅ **Security groups**: Dynamic creation per deployed region  
✅ **Database modules**: Primary/secondary structure with dynamic replicas  
✅ **CloudFront**: Dynamic origins based on deployed regions  
✅ **Lambda@Edge**: Dynamic region mapping for geo-routing  

### Partially Generalized Components
⚠️ **Data module**: Primary region fully dynamic, secondary regions limited to Ireland  
⚠️ **Network module**: VPC peering still hardcoded between specific regions  

## Future Enhancements

To achieve full generalization:

1. **Region-specific data modules**: Create separate data modules for each region
2. **Dynamic VPC peering**: Implement a more flexible VPC peering solution
3. **Provider abstraction**: Explore Terraform provider meta-programming or alternative approaches
4. **Automated module generation**: Consider code generation for region-specific modules

## Migration from Old Structure

If migrating from the old hardcoded structure:
1. Update your `terraform.tfvars` to use the new `geo_regions` variable format
2. Run `terraform plan` to review changes
3. Apply changes in stages if needed to minimize downtime

## Testing

Before deploying to production:
1. Validate the configuration: `terraform validate`
2. Plan the deployment: `terraform plan`
3. Apply to a test environment first
4. Verify all regions are properly configured and accessible
