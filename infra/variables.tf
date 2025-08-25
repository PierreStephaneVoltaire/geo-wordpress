variable "geo_regions" {
  description = "Geographic region configuration for deployment"
  type = object({
    primary   = string
    secondary = list(string)
    all       = map(string)
    vpc_cidrs = map(string)
  })
  default = {
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
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "wordpress-geo"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "wpuser"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "ebs_volume_size" {
  description = "EBS volume size for EC2 instances in GB"
  type        = number
  default     = 20
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Initial allocated storage for RDS in GB"
  type        = number
  default     = 20
}

variable "db_max_allocated_storage" {
  description = "Maximum allocated storage for RDS autoscaling in GB"
  type        = number
  default     = 100
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "wordpress"
}

variable "db_engine_version" {
  description = "MariaDB engine version"
  type        = string
  default     = "10.11.8"
}

variable "region_capacity_config" {
  description = "Region-specific Auto Scaling Group capacity configuration"
  type = map(object({
    min_size         = number
    max_size         = number
    desired_capacity = number
  }))
  default = {
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
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Project     = "WordPress-Geo"
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}

variable "admin_email" {
  description = "WordPress admin email address"
  type        = string
  default     = "pvoltaire96@gmail.com"
}

variable "geoblocking_countries" {
  description = <<-EOT
    List of country codes to block access from CloudFront distribution.
    Uses ISO 3166-1 alpha-2 country codes. Leave empty to allow all countries.
    
    Supported country codes include:
    AD, AE, AF, AG, AI, AL, AM, AO, AQ, AR, AS, AT, AU, AW, AX, AZ, BA, BB, BD, BE, BF, BG, BH, BI, BJ, BL, BM, BN, BO, BQ, BR, BS, BT, BV, BW, BY, BZ, CA, CC, CD, CF, CG, CH, CI, CK, CL, CM, CN, CO, CR, CU, CV, CW, CX, CY, CZ, DE, DJ, DK, DM, DO, DZ, EC, EE, EG, EH, ER, ES, ET, FI, FJ, FK, FM, FO, FR, GA, GB, GD, GE, GF, GG, GH, GI, GL, GM, GN, GP, GQ, GR, GS, GT, GU, GW, GY, HK, HM, HN, HR, HT, HU, ID, IE, IL, IM, IN, IO, IQ, IR, IS, IT, JE, JM, JO, JP, KE, KG, KH, KI, KM, KN, KP, KR, KW, KY, KZ, LA, LB, LC, LI, LK, LR, LS, LT, LU, LV, LY, MA, MC, MD, ME, MF, MG, MH, MK, ML, MM, MN, MO, MP, MQ, MR, MS, MT, MU, MV, MW, MX, MY, MZ, NA, NC, NE, NF, NG, NI, NL, NO, NP, NR, NU, NZ, OM, PA, PE, PF, PG, PH, PK, PL, PM, PN, PR, PS, PT, PW, PY, QA, RE, RO, RS, RU, RW, SA, SB, SC, SD, SE, SG, SH, SI, SJ, SK, SL, SM, SN, SO, SR, SS, ST, SV, SX, SY, SZ, TC, TD, TF, TG, TH, TJ, TK, TL, TM, TN, TO, TR, TT, TV, TW, TZ, UA, UG, UM, US, UY, UZ, VA, VC, VE, VG, VI, VN, VU, WF, WS, YE, YT, ZA, ZM, ZW
  EOT
  type        = list(string)
  default     = []
}
