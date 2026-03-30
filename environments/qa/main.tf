locals {
  env = "qa"
  common_tags = {
    Project     = "HealthApp"
    Environment = "qa"
    ManagedBy   = "Terraform"
  }
}

module "vpc" {
  source = "../../modules/vpc"
  env    = local.env
  cidr   = "10.10.0.0/16"
  common_tags = local.common_tags
}

module "security_groups" {
  source = "../../modules/security-groups"
  env    = local.env
  vpc_id = module.vpc.vpc_id
}

module "compute" {
  source            = "../../modules/ec2-instance"
  env               = local.env
  ami_id            = "ami-0c2016462719f9b5a"
  instance_type     = "t3.micro"
  key_name          = "key_learn_aws_instance_free"
  subnet_id         = module.vpc.public_subnet_ids[0]
  security_group_id = module.security_groups.web_sg_id
  common_tags       = local.common_tags
}
