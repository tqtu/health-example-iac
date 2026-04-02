locals {
  env = "qa"

  common_tags = {
    Project     = "HealthApp"
    Environment = "qa"
    ManagedBy   = "Terraform"
  }
}

# Pulling networking from your core S3 bucket
data "terraform_remote_state" "qa_core" {
  backend = "s3"
  config = {
    bucket = "unboundshare-infra-storage-31-03-2026-1"
    key    = "environments/qa/terraform.tfstate"
    region = "ap-southeast-2"
  }
}

# =========================
# ULTRA-LIGHT EKS FOR DEMO
# =========================
module "eks_qa" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "unboundshare-${local.env}-cluster"
  cluster_version = "1.29"

  vpc_id     = data.terraform_remote_state.qa_core.outputs.vpc_id
  subnet_ids = data.terraform_remote_state.qa_core.outputs.private_subnets

  # ❌ DISABLE HEAVY FEATURES
  create_cloudwatch_log_group            = false # Saves RAM & Money
  cluster_endpoint_public_access         = true
  enable_cluster_creator_admin_permissions = true

  # ❌ OPTIONAL: Reduce Add-on resources (CoreDNS/Kube-Proxy)
  # By default, these are small, but avoid installing "Metrics Server"
  # or "Fluentd/Prometheus" via Helm later.

  eks_managed_node_groups = {
    demo_node = {
      # THE ABSOLUTE MINIMUM
      min_size     = 1
      max_size     = 1
      desired_size = 1

      instance_types = ["t3.micro"] # 1GB RAM
      capacity_type  = "ON_DEMAND"

      # Essential for pulling your "hello-backend" from ECR
      iam_role_additional_policies = {
        AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
      }

      # Clean up storage to keep the node light
      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 20
            volume_type           = "gp3"
            delete_on_termination = true
          }
        }
      }
    }
  }

  tags = local.common_tags
}