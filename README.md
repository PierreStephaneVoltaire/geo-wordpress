# WordPress Global Infrastructure on AWS

## Table of Contents
1. [Overview](#overview)
2. [Technologies & AWS Services](#technologies--aws-services)
3. [Architecture Components](#architecture-components)
4. [Key Features](#key-features)
5. [Configuration](#configuration)
6. [Deployment Process](#deployment-process)
7. [Network Architecture](#network-architecture)
8. [Optimizations & Design Decisions](#optimizations--design-decisions)

## Overview

This solution provides a globally distributed WordPress infrastructure on AWS, optimized for customers primarily located in Ireland (30%) and Singapore (60%), with the remaining 10% spread globally. The infrastructure emphasizes **uptime**, **low latency**, **load handling**, **optimization**, **scalability**, and **operational simplicity** while supporting geographical restrictions.

### Requirements Addressed
- **Global Traffic**: Handles 10k average hourly users with peak capacity for 40k users
- **Geographic Distribution**: Optimized for Ireland (30%) and Singapore (60%) customer base
- **High Availability**: Multi-region architecture targeting 99.9%+ uptime
- **Low Latency**: Regional deployment with CloudFront CDN for global performance
- **Scalability**: Auto Scaling Groups with dynamic capacity adjustment
- **Geographic Restrictions**: CloudFront geo-blocking for compliance requirements
- **Operational Simplicity**: Fully automated deployment and configuration management
### URLS
- jenkins: http://15.223.176.1:8080/
- cloudfront: http://d2lq8jvpkgq0h8.cloudfront.net




## Technologies & AWS Services

### Core AWS Services
- **Compute**: EC2 Auto Scaling Groups, Application Load Balancers
- **Database**: RDS MariaDB with cross-region read replicas
- **Networking**: VPC, VPC Peering, Security Groups, Route Tables
- **Storage**: S3 for media files, EBS for instance storage
- **CDN**: CloudFront with Lambda@Edge functions
- **Security**: IAM Roles, Parameter Store (encrypted)
- **Monitoring**: CloudWatch Metrics and Alarms

### Infrastructure & Automation Tools
- **Infrastructure as Code**: Terraform (modular design)
- **Configuration Management**: Ansible with Geerling Guy roles
- **CI/CD**: Jenkins (standalone infrastructure)
- **Version Control**: GitHub integration
- **Instance Bootstrap**: Cloud-Init with embedded Ansible playbooks

### Application Stack
- **Web Server**: Apache HTTP Server
- **Application**: WordPress (latest) with PHP 8.x
- **Database Engine**: MariaDB 10.11.8
- **Caching**: APCu, OPcache
- **WordPress Plugins**: WP Offload Media, Astra theme, HyperDB

## Architecture Components

### Core Infrastructure (`infra/` folder)

**Multi-Region Deployment:**
- **Primary Region**: Singapore (`ap-southeast-1`) - Houses the primary MariaDB database and compute resources
- **Secondary Region**: Ireland (`eu-west-1`) - Contains read replicas and compute resources for European users

**Database Architecture and Network:**
- **Primary Database**: MariaDB 10.11.8 in Singapore (configurable: `db.t3.micro` default, up to 100GB auto-scaling storage)
- **Read Replicas**: Cross-region replicas in Ireland for improved read performance
- **VPC Peering**: Direct connectivity between Singapore (`10.0.0.0/16`) and Ireland (`10.1.0.0/16`) VPCs

**Compute Layer:**
- **Auto Scaling Groups**: Independent scaling in each region
  - Singapore: 0-4 instances (desired: 2)
  - Ireland: 0-4 instances (desired: 1)
- **Instance Type**: `t3.micro` (configurable)
- **Load Balancers**: Application Load Balancers in each region with HTTP (port 80) and HTTPS redirect (port 443)
- **EBS Volumes**: Encrypted GP3 volumes (20GB default, configurable)
- **Auto Scaling Policies**: Dynamic scaling based on CloudWatch metrics
  - **Scale Up**: CPU > 80% or Memory > 80% (adds 1 instance, 10-minute cooldown)
  - **Scale Down**: CPU < 10% (removes 1 instance, 10-minute cooldown)
- **CloudWatch Alarms**: CPU and memory utilization monitoring for automatic scaling triggers

**Networking:**
- **Cross-Region VPC Peering**: Bidirectional routing between regions for database replication and access
- **Security Groups**: Regional isolation with specific CIDR access (`10.0.0.0/16`, `10.1.0.0/16`)
- **Route Tables**: Automated peering route creation for cross-region connectivity

**Content Delivery:**
- **CloudFront**: Global CDN with dual-origin configuration
  - **Primary Origin**: Singapore ALB for Singapore/Asia-Pacific traffic
  - **Secondary Origin**: Ireland ALB for European traffic
- **Lambda@Edge Functions**: Origin selection and traffic routing based on user geolocation
- **Geographical Restrictions**: Configurable country-level blocking via `geoblocking_countries` variable
- **S3 Integration**: WordPress media offloading with WP Offload Media plugin
- **HTTP Only**: HTTPS not implemented to reduce complexity and stay within project timeline

**Security & Configuration Management:**
- **Parameter Store**: Encrypted storage for database credentials, S3 bucket names, and CloudFront domains
- **IAM Roles**: EC2 instances with Parameter Store and S3 access permissions
- **Read/Write Database Splitting**: WordPress configured for regional read optimization

### Automation & CI/CD

**Jenkins Infrastructure (`jenkins/` folder):**
- **Standalone Infrastructure**: Completely separate Terraform stack with independent networking
- **Jenkins Server**: `t3.micro` instance with dedicated VPC and security groups
- **Automated Configuration**: Jenkins instance configured via Ansible playbook embedded in user data
- **GitHub Integration**: 
  - Connects to `PierreStephaneVoltaire/geo-wordpress` repository
  - Reads and executes `pipelines/Jenkinsfile` directly from GitHub
  - Webhook-triggered pipeline execution on repository changes
- **IAM Roles**: Terraform execution permissions for infrastructure automation
- **Security**: Isolated network environment with restricted access

**Pipeline (`pipelines/Jenkinsfile`):**
- **Validation Stage**: Terraform format and validation checks
- **Planning Stage**: Terraform plan with approval gates for infrastructure changes
- **Application Stage**: Terraform apply with remote state management
- **GitHub Integration**: Automated pipeline execution from repository changes

**WordPress Deployment (`templates/wordpress_test_userdata.tpl`):**
- **Cloud-Init + Embedded Ansible**: Fully automated WordPress installation and configuration
  - Ansible playbook embedded directly in cloud-init user data
  - Executes automatically on every instance launch via Auto Scaling Group
  - No external configuration management required - completely self-contained
- **Package Installation**: Apache, PHP 8.x, MariaDB client, essential WordPress dependencies
- **Database Optimization**: 
  - Initial setup connects to Singapore primary database
  - Post-installation reconfiguration implements read/write splitting
  - Ireland instances read from local replica, write to Singapore primary
- **Plugin Integration**: 
  - WP Offload Media for S3 storage
  - Astra theme for performance
  - HyperDB for database optimization
- **Performance Features**: APCu caching, OPcache, optimized PHP configuration
- **Auto Scaling Integration**: Each new instance automatically configures itself without manual intervention

## Key Features

### Load Handling & Traffic Management
- **Traffic Distribution**: CloudFront distributes 10k average hourly users globally with peak capacity for 40k users
- **Regional Load Balancing**: Application Load Balancers in each region distribute traffic across multiple instances
- **Auto Scaling Response**: Dynamic scaling handles traffic spikes automatically
  - Scale up triggers at 80% CPU/Memory utilization
  - Maximum 4 instances per region (8 total) for peak load handling
- **Global CDN**: CloudFront caches static content globally, reducing origin server load
- **Database Read Optimization**: Read replicas reduce database load by serving local read traffic

### Performance Optimization
- **Regional Read Replicas**: Ireland instances read from local database replica
- **Database Write Routing**: All write operations directed to Singapore primary
- **CloudFront CDN**: Global content caching and delivery
- **Auto Scaling**: CPU and memory-based scaling (scale up at 80% CPU, scale down at 10% CPU)
- **Load Balancing**: Health check-based traffic distribution

### High Availability & Reliability
- **Multi-Region Architecture**: Eliminates single points of failure across geographic regions
- **Auto Scaling Groups**: Automatically replace unhealthy instances within minutes
- **Load Balancer Health Checks**: Continuous health monitoring with 10-second intervals
- **Database Redundancy**: Cross-region read replicas provide data redundancy and failover capability
- **Multi-AZ Resource Distribution**: Resources spread across availability zones within each region
- **Automated Recovery**: Infrastructure self-heals through Auto Scaling and health check mechanisms
- **99.9%+ Uptime Target**: Architecture designed for enterprise-level availability requirements

### Scalability
- **Horizontal Scaling**: Auto Scaling Groups with configurable capacity per region
- **Database Scaling**: RDS storage auto-scaling (20GB to 100GB)
- **Regional Expansion**: Modular design supports additional regions
- **Traffic Management**: CloudFront handles global traffic distribution

### Geographical Controls
- **CloudFront Geo-Blocking**: Configurable country-level access restrictions
- **Regional Routing**: Optimized traffic routing based on user location
- **Compliance Ready**: Infrastructure supports data residency requirements

## Configuration

**Regional Configuration** (`variables.tf`):
```hcl
geo_regions = {
  primary   = "singapore"
  secondary = ["ireland"]
  all = {
    singapore = "ap-southeast-1"
    ireland   = "eu-west-1"
  }
  vpc_cidrs = {
    singapore = "10.0.0.0/16"
    ireland   = "10.1.0.0/16"
  }
}
```

**Capacity Configuration**:
```hcl
region_capacity_config = {
  singapore = {
    min_size         = 0
    max_size         = 4
    desired_capacity = 2
  }
  ireland = {
    min_size         = 0
    max_size         = 4
    desired_capacity = 1  
  }
}
```

**Database Configuration**:
- Instance Class: `db.t3.micro` (configurable)
- Engine: MariaDB 10.11.8
- Storage: 20GB initial, auto-scaling to 100GB
- Backup: 7-day retention period

## Deployment Process

### 1. Jenkins Setup
```bash
cd jenkins/
terraform init
terraform plan
terraform apply
```

### 2. Pipeline Configuration
- Connect Jenkins to GitHub repository `PierreStephaneVoltaire/geo-wordpress`
- Configure pipeline to use `pipelines/Jenkinsfile`
- Set up GitHub webhooks for automated triggering

### 3. Infrastructure Deployment
- Pipeline automatically validates Terraform code
- Manual approval required for infrastructure changes
- Terraform applies infrastructure in dependency order:
  1. Data layer (S3, Parameter Store)
  2. Network layer (VPCs, peering, security groups)
  3. Database layer (primary and replicas)
  4. Compute layer (Auto Scaling Groups, Load Balancers)
  5. CloudFront distribution

### 4. WordPress Installation
- Cloud-init automatically installs and configures WordPress
- Ansible playbook handles:
  - Apache and PHP installation via Geerling Guy roles
  - WordPress core installation via WP-CLI
  - Plugin installation and activation
  - Database connection optimization
  - Regional read/write splitting configuration

## Technology Stack

**Infrastructure as Code**: Terraform with modular design
- Network module: VPC, subnets, peering, security groups
- Compute module: Auto Scaling, Load Balancers, CloudWatch alarms
- Database module: RDS primary and read replicas
- Security module: IAM roles, security groups
- Data module: S3, Parameter Store, CloudFront

**Configuration Management**: Ansible
- Geerling Guy roles for Apache and PHP
- Custom playbooks for WordPress optimization
- AWS SSM Parameter Store integration

**CI/CD**: Jenkins with GitHub integration
- Terraform validation and planning
- Approval gates for production changes
- State management and drift detection

**Application Stack**:
- **Web Server**: Apache HTTP Server with virtual hosts
- **Application**: WordPress (latest) with performance plugins
- **Database**: MariaDB 10.11.8 with read/write splitting
- **Caching**: APCu, OPcache, CloudFront CDN
- **Storage**: S3 for media files, EBS for application data

**Monitoring & Scaling**:
- CloudWatch metrics and alarms
- Auto Scaling based on CPU/memory utilization
- ELB health checks for instance health
- Memory utilization monitoring via CloudWatch agent

## Network Architecture

**Cross-Region Connectivity**:
- VPC peering connection initiated by Singapore (primary)
- Ireland accepts peering and creates return routes
- Bidirectional routing for database replication traffic
- Security groups allow cross-region database access

**Database Connectivity Flow**:
```
Ireland WordPress → Ireland Read Replica (local reads)
Ireland WordPress → Singapore Primary (writes via peering)
Singapore WordPress → Singapore Primary (local reads/writes)
```

**Traffic Flow**:
```
Global Users → CloudFront → Regional ALBs → Auto Scaling Groups → WordPress Instances
```

This solution provides a production-ready, globally distributed WordPress infrastructure optimized for the specified geographical distribution while maintaining high availability, performance, and operational simplicity through comprehensive automation.

## Optimizations & Design Decisions

### Free Tier Considerations
- **Single-AZ Databases**: RDS instances deployed in single availability zones to remain within AWS free tier limits. Multi-AZ deployment would provide higher availability but exceeds free tier constraints.
- **Public Subnets for Compute**: EC2 instances placed in public subnets to avoid NAT Gateway costs required for private subnet internet access during WordPress installation and updates.
- **No Domain Registration**: Solution uses bare IP addresses and CloudFront domain names instead of custom domains to avoid Route 53 and domain registration costs.

### Infrastructure Limitations
- **Hardcoded Regions**: Singapore and Ireland regions are hardcoded due to Terraform provider limitations. OpenTofu would enable dynamic region looping, making the solution more modular across:
  - Network modules and VPC peering
  - Compute deployments 
  - Database replicas
  - Peering accepters and route tables

### WordPress Deployment Complexity
- **Manual Installation Process**: Current Ansible playbook handles WordPress installation manually due to limited familiarity with existing comprehensive WordPress roles. Alternative approaches that could simplify deployment:
  - **Docker-based Deployment**: Running WordPress in containers with environment variable configuration
  - **Comprehensive Ansible Roles**: Using more complete WordPress automation roles from Ansible Galaxy
  - **WordPress CLI Automation**: More extensive use of WP-CLI for plugin and theme management

### Database Configuration Challenges
- **HyperDB Plugin Limitations**: The HyperDB plugin requires an existing WordPress database schema, necessitating a two-phase configuration:
  1. Initial setup with primary database connection
  2. Post-installation reconfiguration for read/write splitting
- **VPC Peering vs Public Access**: While making databases publicly accessible would have simplified cross-region connectivity, VPC peering was chosen for enhanced security despite added complexity.

### Potential Improvements
- **Multi-Region Modularity**: Refactor to support dynamic region deployment through configuration loops
- **Container-Based WordPress**: Implement Docker deployment for simplified configuration management
- **Database High Availability**: Implement Multi-AZ when moving beyond free tier constraints
- **Private Subnet Architecture**: Add NAT Gateways for enhanced security when budget permits
- **Automated WordPress Role**: Integrate more comprehensive WordPress automation roles
- **Custom Domain Integration**: Add Route 53 and domain management for production use cases
