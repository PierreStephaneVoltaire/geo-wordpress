# WordPress Global Infrastructure v2 - Fargate Edition

## Overview

This is a complete rewrite of the WordPress infrastructure using modern AWS services:

- **ECS Fargate** instead of EC2 Auto Scaling Groups
- **Aurora Global Database** for global read replicas
- **CloudFront + Lambda@Edge** for intelligent geo-routing
- **ElastiCache Redis** for session and object caching
- **S3 Cross-Region Replication** for media assets
- **Parameter Store** for secure credential management

## Architecture

### Global Components
- CloudFront distribution with Lambda@Edge geo-routing
- S3 primary bucket with cross-region replication
- Aurora Global Database cluster
- Parameter Store for configuration

### Regional Components (Per Region)
- VPC with public/private/database subnets
- Application Load Balancer (ALB)
- ECS Fargate cluster running WordPress
- ElastiCache Redis for caching
- Security groups and networking

## Prerequisites

1. AWS CLI configured with appropriate permissions
2. Terraform >= 1.0
3. Docker (for custom WordPress image)

## Deployment Instructions

### 1. Initialize Terraform

```bash
cd infra-v2
terraform init
```

### 2. Review Variables

Edit `variables.tf` or create a `terraform.tfvars` file:

```hcl
regions = {
  singapore = {
    region     = "ap-southeast-1"
    vpc_cidr   = "10.0.0.0/16"
    is_primary = true
    fargate = {
      min_capacity     = 1
      max_capacity     = 10
      desired_capacity = 2
    }
  }
  ireland = {
    region     = "eu-west-1"
    vpc_cidr   = "10.1.0.0/16"
    is_primary = false
    fargate = {
      min_capacity     = 1
      max_capacity     = 8
      desired_capacity = 1
    }
  }
}

admin_email = "your-email@example.com"
geoblocking_countries = ["CN", "RU"]  # Optional
```

### 3. Quick Start (Pre-Generated Plan Available!)

A ready-to-deploy Terraform plan has been pre-generated and saved as `terraform-plan.out` with detailed output in `terraform-plan-output.txt`.

**To deploy immediately:**
```bash
terraform apply terraform-plan.out
```

**To review the plan details:**
```bash
cat terraform-plan-output.txt
```

**To generate a fresh plan:**
```bash
terraform plan
terraform apply
```

### 4. Build and Deploy Custom WordPress Image

```bash
# Navigate to docker directory
cd docker

# Build the custom WordPress image
docker build -t wordpress-aws .

# Tag for ECR (replace with your account ID and region)
docker tag wordpress-aws:latest 123456789012.dkr.ecr.us-east-1.amazonaws.com/wordpress-geo:latest

# Push to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 123456789012.dkr.ecr.us-east-1.amazonaws.com
docker push 123456789012.dkr.ecr.us-east-1.amazonaws.com/wordpress-geo:latest
```

## Features

### WordPress Enhancements

1. **S3 Media Offloading**: All uploads automatically stored in S3
2. **Redis Object Caching**: Improved performance with Redis cache
3. **Database Read/Write Splitting**: Optimized database performance
4. **Parameter Store Integration**: Secure credential management
5. **CloudFront Integration**: Global CDN with geo-routing

### Infrastructure Features

1. **Auto Scaling**: Fargate services scale based on CPU/memory
2. **High Availability**: Multi-AZ deployments
3. **Security**: All credentials in Parameter Store, encrypted storage
4. **Cost Optimization**: Conservative instance sizes, Fargate pricing
5. **Monitoring**: CloudWatch logs and metrics

## Module Structure

```
improved-infra/
├── main.tf                           # Main configuration
├── variables.tf                      # Input variables
├── outputs.tf                        # Output values
├── providers.tf                      # AWS provider configuration
├── backend.tf                        # Terraform state backend
├── terraform-plan.out               # Pre-generated deployment plan
├── terraform-plan-output.txt        # Detailed plan output for review
├── modules/
│   ├── global-storage/              # S3 buckets and replication
│   ├── cloudfront/                  # CloudFront + Lambda@Edge
│   ├── regional-infrastructure/     # VPC, subnets, security groups
│   ├── global-database/            # Aurora Global Database
│   ├── wordpress-fargate/          # ECS Fargate + ALB + Redis
│   └── parameter-store/            # AWS Systems Manager Parameter Store
└── docker/
    ├── Dockerfile                   # Custom WordPress image
    ├── wp-config-extra.php         # WordPress configuration
    ├── db-config.php              # Database splitting config
    └── entrypoint.sh              # Container startup script
```

## Outputs

After deployment, you'll get:

- `cloudfront_distribution_domain_name`: Your WordPress site URL
- `regional_alb_endpoints`: Direct ALB endpoints for each region
- `aurora_global_cluster_id`: Database cluster identifier
- `s3_bucket_name`: Media storage bucket name

## Customization

### Adding New Regions

Simply add to the `regions` variable:

```hcl
regions = {
  # Existing regions...
  tokyo = {
    region     = "ap-northeast-1"
    vpc_cidr   = "10.2.0.0/16"
    is_primary = false
    fargate = {
      min_capacity     = 1
      max_capacity     = 5
      desired_capacity = 1
    }
  }
}
```

### Scaling Configuration

Adjust Fargate capacity per region:

```hcl
fargate = {
  min_capacity     = 2    # Minimum containers
  max_capacity     = 20   # Maximum containers
  desired_capacity = 4    # Initial containers
}
```

## Security Considerations

1. All database credentials stored in Parameter Store (SecureString)
2. ECS tasks use IAM roles (no hardcoded credentials)
3. RDS and ElastiCache encrypted at rest and in transit
4. VPC with proper subnet isolation
5. Security groups with minimal required access

## Cost Optimization

### Default Configuration (Optimized for <400 requests/month per region)
- **Fargate**: 0.25 vCPU (256 CPU units), 512MB RAM - **~$8/month per region**
- **Aurora**: db.t4g.medium, single instance - **~$45/month per region** 
- **ElastiCache**: cache.t4g.nano, single node - **~$12/month per region**
- **ALB**: Standard pricing - **~$16/month per region**
- **CloudFront**: Low usage tier - **~$1/month globally**
- **S3**: Minimal storage - **~$3/month globally**

**Estimated Total: ~$165/month for 2 regions**

### Cost Control Variables

Control your costs by adjusting these variables in `terraform.tfvars`:

```hcl
# Aurora Database (biggest cost driver)
aurora_instance_class = "db.t4g.medium"  # Smallest Aurora instance
aurora_instance_count = 1                # Single instance per region

# Fargate Resources (scales with traffic)
fargate_cpu    = 256   # 0.25 vCPU (minimum)
fargate_memory = 512   # 512MB RAM (minimum for WordPress)

# Regional Scaling (for traffic growth)
regions = {
  singapore = {
    fargate = {
      min_capacity     = 1  # Always 1 container minimum
      max_capacity     = 3  # Max 3 containers (handles ~1200 req/month)
      desired_capacity = 1  # Start with 1 container
    }
  }
  ireland = {
    fargate = {
      min_capacity     = 1
      max_capacity     = 3  
      desired_capacity = 1
    }
  }
}
```

### Scaling for Traffic Growth

| Monthly Requests/Region | Recommended max_capacity | Estimated Cost Impact |
|-------------------------|-------------------------|----------------------|
| <400 (current)          | 3                       | $165/month (baseline) |
| 400-1,000               | 5                       | +$16/month |
| 1,000-3,000             | 10                      | +$40/month |
| 3,000+                  | 20                      | +$80/month |

## Monitoring

- ECS Container Insights enabled
- CloudWatch logs for all services
- RDS Performance Insights enabled
- Auto-scaling based on CPU/memory metrics

## Troubleshooting

### Common Issues

1. **ECS Tasks Not Starting**: Check IAM permissions and Parameter Store access
2. **Database Connection Issues**: Verify security group rules and endpoints
3. **S3 Upload Issues**: Check IAM role permissions for ECS tasks
4. **Redis Connection Issues**: Verify ElastiCache security group and subnet configuration

### Useful Commands

```bash
# Check ECS service status
aws ecs describe-services --cluster wordpress-geo-cluster-singapore-xxxx --services wordpress-geo-service-singapore-xxxx

# View container logs
aws logs describe-log-groups --log-group-name-prefix "/ecs/wordpress-geo"

# Test parameter store access
aws ssm get-parameter --name "/wordpress-geo/prod/database/username"
```

## Support

For issues or questions:
1. Check AWS CloudWatch logs
2. Verify Terraform state and outputs
3. Review security group and IAM permissions