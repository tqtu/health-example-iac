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
    values = ["ubuntu/images/hvm-ssd/ubuntu-noble-24.04-amd64-server-*"]
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
  key_name          = "key_learn_aws_instance_free"
  subnet_id         = module.vpc.public_subnet_ids[0]
  security_group_id = module.security_groups.web_sg_id
  common_tags       = local.common_tags
}