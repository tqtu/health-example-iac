
locals {
  env = "prod"

  common_tags = {
    Project     = "HealthApp"
    Environment = "prod"
    ManagedBy   = "Terraform"
  }
}

# =========================
# DYNAMIC AMI (Ubuntu 24.04 - Canonical)
# =========================
data "aws_ami" "ubuntu_prod" {
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
module "vpc_prod" {
  source      = "../../modules/vpc"
  env         = local.env
  cidr        = "10.20.0.0/16"  # Optional: different CIDR for prod
  common_tags = local.common_tags
}

# =========================
# SECURITY GROUPS
# =========================
module "security_groups_prod" {
  source = "../../modules/security-groups"
  env    = local.env
  vpc_id = module.vpc_prod.vpc_id
}

# =========================
# EC2 COMPUTE
# =========================
module "compute_prod" {
  source = "../../modules/ec2-instance"

  env               = local.env
  ami_id            = data.aws_ami.ubuntu_prod.id
  instance_type     = "t3.medium"  # Optional: bigger for prod
  subnet_id         = module.vpc_prod.public_subnet_ids[0]
  security_group_id = module.security_groups_prod.web_sg_id
  common_tags       = local.common_tags
}

# =========================
# CLOUDFRONT for PROD
# =========================
module "cloudfront_prod" {
  source      = "../../modules/cloudfront"
  env         = local.env
  common_tags = local.common_tags

  domain_name           = "unboundshare.com"
  s3_bucket_domain_name = "unboundshare-frontend-storage-31-03-2026-1.s3-website-ap-southeast-1.amazonaws.com"
}

# =========================
# ROUTE53 for PROD
# =========================
data "aws_route53_zone" "selected_prod" {
  name = "unboundshare.com"
}

module "dns_record_prod" {
  source = "../../modules/route53-record"

  hosted_zone_id = data.aws_route53_zone.selected_prod.zone_id
  domain_name    = "unboundshare.com"
  subdomain      = "www"  # or empty for root, or "prod"

  type    = "CNAME"
  records = [module.cloudfront_prod.domain_name]
  ttl     = 300
}