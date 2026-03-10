terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }

  backend "s3" {
    bucket  = "ascom-receipts-app-tfstate-319393fe"
    key     = "gitops-terraform-aks-eks-receipt-app/dev/aws-network/terraform.tfstate"
    region  = "eu-north-1"
    encrypt = true
  }
}