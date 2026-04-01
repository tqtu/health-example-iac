locals {
  env = "production"

  common_tags = {
    Project     = "HealthApp"
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}

# =========================
# DYNAMIC AMI (Ubuntu 24.04 - Canonical)
# =========================
data "aws_ami" "ubuntu_production" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*-amd64-server-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# =========================
# VPC
# =========================
module "vpc_production" {
  source      = "../../modules/vpc"
  env         = local.env
  cidr        = "10.20.0.0/16" # Optional: different CIDR for production
  common_tags = local.common_tags
}

# =========================
# SECURITY GROUPS
# =========================
module "security_groups_production" {
  source = "../../modules/security-groups"
  env    = local.env
  vpc_id = module.vpc_production.vpc_id
}

# =========================
# EC2 COMPUTE
# =========================
module "compute_production" {
  source = "../../modules/ec2-instance"

  env               = local.env
  ami_id            = data.aws_ami.ubuntu_production.id
  instance_type     = "t3.medium" # Bigger instance for production
  subnet_id         = module.vpc_production.public_subnet_ids[0]
  security_group_id = module.security_groups_production.web_sg_id
  common_tags       = local.common_tags
}

# =========================
# CLOUDFRONT for PRODUCTION
# =========================
module "cloudfront_production" {
  source      = "../../modules/cloudfront"
  env         = local.env
  common_tags = local.common_tags

  domain_name           = "unboundshare.com"
  s3_bucket_domain_name = "unboundshare-frontend-storage-31-03-2026-1.s3-website-ap-southeast-1.amazonaws.com"
}

# =========================
# ROUTE53 for PRODUCTION
# =========================
data "aws_route53_zone" "selected_production" {
  name = "unboundshare.com"
}

module "dns_record_production" {
  source = "../../modules/route53-record"

  hosted_zone_id = data.aws_route53_zone.selected_production.zone_id
  domain_name    = "unboundshare.com"
  subdomain      = "www" # or "" for root domain

  type    = "CNAME"
  records = [module.cloudfront_production.domain_name]
  ttl     = 300
}