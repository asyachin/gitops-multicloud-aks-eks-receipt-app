locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# =============================================================================
# REMOTE STATE — IAM (cluster role + node group role ARNs)
# =============================================================================

data "terraform_remote_state" "iam" {
  backend = "s3"
  config = {
    bucket = "ascom-receipts-app-tfstate-319393fe"
    key    = "gitops-terraform-aks-eks-receipt-app/dev/aws-iam/terraform.tfstate"
    region = "eu-north-1"
  }
}

# =============================================================================
# SUBNET LOOKUP  (by kubernetes tags set in aws-network layer)
# =============================================================================

data "aws_vpc" "main" {
  tags = {
    Name = var.vpc_name
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
  tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
  tags = {
    "kubernetes.io/role/elb" = "1"
  }
}

# =============================================================================
# EKS MODULE
# =============================================================================

module "eks" {
  source = "../../../../modules/aws/eks"

  cluster_name        = var.cluster_name
  kubernetes_version  = var.kubernetes_version
  cluster_role_arn    = data.terraform_remote_state.iam.outputs.cluster_role_arn
  node_group_role_arn = data.terraform_remote_state.iam.outputs.node_group_role_arn

  subnet_ids            = concat(data.aws_subnets.public.ids, data.aws_subnets.private.ids)
  node_group_subnet_ids = data.aws_subnets.private.ids

  node_group_name = "${var.cluster_name}-nodes"
  instance_types  = var.instance_types
  disk_size       = var.disk_size
  desired_size    = var.desired_size
  min_size        = var.min_size
  max_size        = var.max_size

  tags = local.common_tags
}
