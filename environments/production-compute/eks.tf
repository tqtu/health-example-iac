module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "unboundshare-prod-cluster"
  cluster_version = "1.29"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  enable_irsa = true

  eks_managed_node_groups = {
    prod_nodes = {
      min_size     = 2
      max_size     = 5 # Allow more scaling in Prod
      desired_size = 2

      instance_types = ["t3.large"] # Stronger CPU/RAM for Prod
      capacity_type  = "ON_DEMAND"
    }
  }

  tags = {
    Environment = "production"
  }
}