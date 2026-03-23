data "terraform_remote_state" "network" {
  backend = "azurerm"
  config = {
    container_name       = "tfstate"
    resource_group_name  = "rg-tfstate"
    storage_account_name = "recipiptsu745"
    key                  = "gitops-multicloud-aks-eks-receipt-app/infra/live/azure/dev/az-network/terraform.tfstate"
  }
}

locals {
  network = data.terraform_remote_state.network.outputs

  tags = {
    project     = var.project
    environment = var.environment
  }
}

module "aks" {
  source = "../../../../modules/azure/aks"

  cluster_name        = var.cluster_name
  location            = local.network.resource_group_location
  resource_group_name = local.network.resource_group_name
  dns_prefix          = var.dns_prefix
  kubernetes_version  = var.kubernetes_version

  automatic_channel_upgrade = var.automatic_channel_upgrade
  azure_policy_enabled      = var.azure_policy_enabled

  system_node_count  = var.system_node_count
  system_vm_size     = var.system_vm_size
  system_subnet_id   = local.network.subnet_ids["subnet-aks-system"]
  availability_zones = local.network.availability_zones
  os_disk_size_gb    = var.os_disk_size_gb

  tags = local.tags
}
