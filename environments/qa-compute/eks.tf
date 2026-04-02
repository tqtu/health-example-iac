# =========================
# ULTRA-LIGHT EKS FOR DEMO
# =========================
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "unboundshare-qa-cluster"
  cluster_version = "1.29"

  # 🔗 FIX: Pull from Remote State instead of local module
  vpc_id     = data.terraform_remote_state.qa_core.outputs.vpc_id
  subnet_ids = data.terraform_remote_state.qa_core.outputs.private_subnets

  # ❌ DISABLE UNNECESSARY FEATURES (Save RAM for t3.micro)
  create_cloudwatch_log_group            = false
  cluster_endpoint_public_access         = true
  enable_cluster_creator_admin_permissions = true

  # Enabling IAM Roles for Service Accounts
  enable_irsa = true

  eks_managed_node_groups = {
    qa_nodes = {
      # THE ABSOLUTE MINIMUM FOR DEMO
      min_size     = 1
      max_size     = 1
      desired_size = 1

      instance_types = ["t3.micro"] # 1GB RAM
      capacity_type  = "ON_DEMAND"

      # 🔐 REQUIRED: Allow the node to pull your images from ECR
      iam_role_additional_policies = {
        AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
      }
    }
  }

  tags = {
    Environment = "qa"
    Project     = "HealthApp"
  }
}