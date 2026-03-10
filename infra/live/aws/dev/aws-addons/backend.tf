terraform {
  required_version = ">= 1.5.0"

  required_providers {
    http       = { source = "hashicorp/http", version = ">= 3.0" }
    aws        = { source = "hashicorp/aws", version = ">= 5.0" }
    helm       = { source = "hashicorp/helm", version = ">= 2.12" }
    kubernetes = { source = "hashicorp/kubernetes", version = ">= 2.27" }
  }

  backend "s3" {
    bucket  = "ascom-receipts-app-tfstate-319393fe"
    key     = "gitops-terraform-aks-eks-receipt-app/dev/aws-addons/terraform.tfstate"
    region  = "eu-north-1"
    encrypt = true
  }
}

provider "aws" {
  region = var.region
}

# Helm + Kubernetes провайдеры берут данные из EKS
data "aws_eks_cluster" "main" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "main" {
  name = var.cluster_name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.main.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.main.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.main.token
}

provider "helm" {
  kubernetes = {
    host                   = data.aws_eks_cluster.main.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.main.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.main.token
  }
}
