#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🚀 Building PRODUCTION-GRADE IaC Structure for Luca...${NC}"

# 1. Create Comprehensive Directory Structure
mkdir -p bootstrap global/iam global/route53 \
         modules/vpc modules/security-groups modules/ec2-instance modules/rds \
         environments/qa environments/staging environments/prod

# ---------------------------------------------------------
# 2. BOOTSTRAP: The "State of States"
# ---------------------------------------------------------
echo "Generating Bootstrap Layer..."
cat <<EOF > bootstrap/main.tf
provider "aws" { region = "ap-southeast-2" }

resource "aws_s3_bucket" "terraform_state" {
  bucket = "luca-terraform-state-storage-\${random_id.suffix.hex}"
  force_destroy = true
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-state-locking"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  attribute { name = "LockID", type = "S" }
}

resource "random_id" "suffix" { byte_length = 4 }
EOF

# ---------------------------------------------------------
# 3. MODULE: VPC (Production Grade - Multi-AZ)
# ---------------------------------------------------------
echo "Generating Advanced VPC Module..."
cat <<EOF > modules/vpc/main.tf
resource "aws_vpc" "this" {
  cidr_block           = var.cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = merge(var.common_tags, { Name = "\${var.env}-vpc" })
}

resource "aws_subnet" "public" {
  count             = 2
  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(var.cidr, 8, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags = merge(var.common_tags, { Name = "\${var.env}-public-\${count.index}" })
}

data "aws_availability_zones" "available" {}

output "vpc_id" { value = aws_vpc.this.id }
output "public_subnet_ids" { value = aws_subnet.public[*].id }
EOF

cat <<EOF > modules/vpc/variables.tf
variable "cidr" {}
variable "env" {}
variable "common_tags" { type = map(string) }
EOF

# ---------------------------------------------------------
# 4. MODULE: SECURITY GROUPS (Isolated)
# ---------------------------------------------------------
echo "Generating Security Groups Module..."
cat <<EOF > modules/security-groups/main.tf
resource "aws_security_group" "web_sg" {
  name        = "\${var.env}-web-sg"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip] 
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "web_sg_id" { value = aws_security_group.web_sg.id }
EOF

cat <<EOF > modules/security-groups/variables.tf
variable "vpc_id" {}
variable "env" {}
variable "my_ip" { default = "0.0.0.0/0" }
EOF

# ---------------------------------------------------------
# 5. MODULE: EC2 (Standardized)
# ---------------------------------------------------------
echo "Generating EC2 Module..."
cat <<EOF > modules/ec2-instance/main.tf
resource "aws_instance" "app" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = var.subnet_id
  vpc_security_group_ids = [var.security_group_id]
  key_name      = var.key_name

  user_data = file("\${path.module}/scripts/install_docker.sh")

  tags = merge(var.common_tags, { Name = "\${var.env}-server" })
}
EOF

mkdir -p modules/ec2-instance/scripts
cat <<EOF > modules/ec2-instance/scripts/install_docker.sh
#!/bin/bash
sudo apt update -y
sudo apt install -y docker.io docker-compose-v2
sudo systemctl start docker
sudo usermod -aG docker ubuntu
EOF

cat <<EOF > modules/ec2-instance/variables.tf
variable "ami_id" {}
variable "instance_type" {}
variable "subnet_id" {}
variable "security_group_id" {}
variable "key_name" {}
variable "env" {}
variable "common_tags" { type = map(string) }
EOF

# ---------------------------------------------------------
# 6. ENVIRONMENT: QA (Implementation)
# ---------------------------------------------------------
echo "Wiring up QA Environment..."
cat <<EOF > environments/qa/main.tf
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
EOF

# Dummy backend file for structure
cat <<EOF > environments/qa/backend.tf
# terraform {
#   backend "s3" {
#     bucket         = "YOUR_BUCKET_NAME_FROM_BOOTSTRAP"
#     key            = "environments/qa/terraform.tfstate"
#     region         = "ap-southeast-2"
#     dynamodb_table = "terraform-state-locking"
#   }
# }
EOF

# Finalize
echo -e "${GREEN}✅ Done! Enterprise Structure Created.${NC}"