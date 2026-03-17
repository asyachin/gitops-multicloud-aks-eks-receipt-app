terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0.0"
    }
  }

  backend "azurerm" {
    container_name       = "tfstate"
    resource_group_name  = "rg-tfstate"
    storage_account_name = "recipiptsu745"
    key                  = "gitops-multicloud-aks-eks-receipt-app/infra/live/azure/dev/az-network/terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}
