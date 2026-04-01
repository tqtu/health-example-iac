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
  owners      = ["099720109477"]

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
# IMPORT VPC & SG from production remote state
# =========================
data "terraform_remote_state" "production_core" {
  backend = "s3"
  config = {
    bucket = "unboundshare-infra-storage-31-03-2026-1"
    key    = "environments/production/terraform.tfstate"
    region = "ap-southeast-2"
  }
}

# =========================
# EC2 COMPUTE
# =========================
module "compute_production" {
  source = "../../modules/ec2-instance"

  env               = local.env
  ami_id            = data.aws_ami.ubuntu_production.id
  instance_type     = "t3.medium"
  subnet_id         = data.terraform_remote_state.production_core.outputs.public_subnet_id
  security_group_id = data.terraform_remote_state.production_core.outputs.web_sg_id
  common_tags       = local.common_tags
}