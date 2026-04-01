locals {
  env = "qa"

  common_tags = {
    Project     = "HealthApp"
    Environment = "qa"
    ManagedBy   = "Terraform"
  }
}

# =========================
# DYNAMIC AMI (Ubuntu 24.04 - Canonical)
# =========================
data "aws_ami" "ubuntu" {
  most_recent = true

  owners = ["099720109477"] # Canonical

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
# EC2 COMPUTE
# =========================
module "compute" {
  source = "../../modules/ec2-instance"

  env               = local.env
  ami_id            = data.aws_ami.ubuntu.id
  instance_type     = "t3.micro"
  subnet_id         = module.vpc.public_subnet_ids[0]
  security_group_id = module.security_groups.web_sg_id
  common_tags       = local.common_tags
}

# =========================
# ROUTE
# =========================
# 2. Create the Hosted Zone (The $0.50 resource)
# 1. Look up the existing zone created in the Global folder
data "aws_route53_zone" "selected" {
  name = "unboundshare.com"
}

# 2. Call the record module with a corrected path
module "dns_record_qa" {
  source = "../../global/route53"

  hosted_zone_id      = data.aws_route53_zone.selected.zone_id
  domain_name         = "unboundshare.com"
  subdomain           = "qa"

  s3_website_endpoint = "unboundshare-frontend-qa-31-03-2026-1.s3-website-ap-southeast-1.amazonaws.com"
  s3_hosted_zone_id   = "Z3O0J2DX0C6PQG"

  common_tags         = local.common_tags
}