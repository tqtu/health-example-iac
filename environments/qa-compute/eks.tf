module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "unboundshare-qa-cluster"
  cluster_version = "1.29"

  vpc_id     = data.terraform_remote_state.qa_core.outputs.vpc_id
  subnet_ids = data.terraform_remote_state.qa_core.outputs.private_subnets

  create_kms_key = true
  cluster_encryption_config = {
    resources = ["secrets"]
  }

  create_cloudwatch_log_group              = false
  cluster_endpoint_public_access           = true
  enable_cluster_creator_admin_permissions = true
  enable_irsa                              = true

  eks_managed_node_groups = {
    qa_nodes = {
      min_size     = 1
      max_size     = 1
      desired_size = 1

      instance_types = ["t3.micro"]
      capacity_type  = "ON_DEMAND"

      ami_type = "AL2_x86_64"

      iam_role_additional_policies = {
        AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
      }
    }
  }
}