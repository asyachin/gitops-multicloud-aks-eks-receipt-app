
terraform {
  backend "s3" {
    bucket  = ascom-receipts-app-tfstate-319393fe
    key     = gitops-terraform-aks-eks-receipt-app/dev/terraform.tfstate
    region  = eu-north-1
    encrypt = true
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.1.0"
    }
  }
}
