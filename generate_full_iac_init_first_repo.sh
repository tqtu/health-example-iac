#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Building Enterprise IaC Structure for Luca...${NC}"

# 1. Create Directory Structure
mkdir -p modules/vpc modules/ec2-instance environments/qa/

# ---------------------------------------------------------
# 2. MODULE: VPC
# ---------------------------------------------------------
echo "Generating VPC Module..."

cat <<EOF > modules/vpc/variables.tf
variable "env" {}
variable "aws_region" {}
variable "vpc_cidr" {}
variable "public_subnet_cidr" {}
EOF

cat <<EOF > modules/vpc/main.tf
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  tags = { Name = "\${var.env}-vpc" }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  map_public_ip_on_launch = true
  tags = { Name = "\${var.env}-public-subnet" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}
EOF

cat <<EOF > modules/vpc/outputs.tf
output "vpc_id" { value = aws_vpc.main.id }
output "public_subnet_id" { value = aws_subnet.public.id }
EOF

# ---------------------------------------------------------
# 3. MODULE: EC2-INSTANCE
# ---------------------------------------------------------
echo "Generating EC2 Module..."

cat <<EOF > modules/ec2-instance/variables.tf
variable "env" {}
variable "vpc_id" {}
variable "subnet_id" {}
variable "ami_id" {}
variable "instance_type" {}
variable "key_name" {}
EOF

cat <<EOF > modules/ec2-instance/main.tf
resource "aws_security_group" "app_sg" {
  name   = "\${var.env}-app-sg"
  vpc_id = var.vpc_id

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
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "this" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = var.subnet_id
  key_name      = var.key_name
  vpc_security_group_ids = [aws_security_group.app_sg.id]

  user_data = <<-EOT
              #!/bin/bash
              sudo apt update -y
              sudo apt install -y docker.io docker-compose-v2
              sudo systemctl start docker
              sudo usermod -aG docker ubuntu
              EOT

  tags = { Name = "\${var.env}-server" }
}
EOF

cat <<EOF > modules/ec2-instance/outputs.tf
output "server_public_ip" { value = aws_instance.this.public_ip }
EOF

# ---------------------------------------------------------
# 4. ENVIRONMENT: QA
# ---------------------------------------------------------
echo "Generating QA Environment..."

cat <<EOF > environments/qa/providers.tf
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-southeast-2"
}
EOF

cat <<EOF > environments/qa/main.tf
module "network" {
  source             = "../../modules/vpc"
  env                = "qa"
  aws_region         = "ap-southeast-2"
  vpc_cidr           = "10.10.0.0/16"
  public_subnet_cidr = "10.10.1.0/24"
}

module "compute" {
  source        = "../../modules/ec2-instance"
  env           = "qa"
  vpc_id        = module.network.vpc_id
  subnet_id     = module.network.public_subnet_id
  ami_id        = "ami-0c2016462719f9b5a" # Ubuntu 24.04 Sydney
  instance_type = "t3.micro"
  key_name      = "key_learn_aws_instance_free"
}

output "qa_server_ip" {
  value = module.compute.server_public_ip
}
EOF

# 5. Finalize
touch .gitignore
echo ".terraform/" >> .gitignore
echo "*.tfstate*" >> .gitignore
echo ".terraform.lock.hcl" >> .gitignore

echo -e "${GREEN}Done! Full IaC Architecture generated.${NC}"
echo -e "To deploy QA: ${BLUE}cd environments/qa && terraform init && terraform apply${NC}"