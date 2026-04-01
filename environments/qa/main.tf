locals {
  env = "qa"

  common_tags = {
    Project     = "HealthApp"
    Environment = "qa"
    ManagedBy   = "Terraform"
  }
}

# =========================
# VPC
# =========================
module "vpc" {
  source      = "../../modules/vpc"
  env         = local.env
  cidr        = "10.10.0.0/16"
  common_tags = local.common_tags
}

# =========================
# SECURITY GROUPS
# =========================
module "security_groups" {
  source = "../../modules/security-groups"
  env    = local.env
  vpc_id = module.vpc.vpc_id
}

# =========================
# CLOUDFRONT for QA
# =========================
module "cloudfront_qa" {
  source      = "../../modules/cloudfront"
  env         = local.env
  common_tags = local.common_tags

  domain_name           = "unboundshare.com"
  s3_bucket_domain_name = "unboundshare-frontend-qa-31-03-2026-1.s3-website-ap-southeast-1.amazonaws.com"
}

# =========================
# ROUTE53 for QA
# =========================
data "aws_route53_zone" "selected" {
  name = "unboundshare.com"
}

module "dns_record_qa" {
  source = "../../modules/route53-record"

  hosted_zone_id = data.aws_route53_zone.selected.zone_id
  domain_name    = "unboundshare.com"
  subdomain      = "qa"

  type    = "CNAME"
  records = [module.cloudfront_qa.domain_name]
  ttl     = 300
}