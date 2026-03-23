resource "azurerm_kubernetes_cluster" "main" {
  name                      = var.cluster_name
  location                  = var.location
  resource_group_name       = var.resource_group_name
  dns_prefix                = var.dns_prefix
  kubernetes_version        = var.kubernetes_version
  automatic_upgrade_channel = var.automatic_channel_upgrade
  azure_policy_enabled      = var.azure_policy_enabled
  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  default_node_pool {
    name                         = "system"
    node_count                   = var.system_node_count
    vm_size                      = var.system_vm_size
    vnet_subnet_id               = var.system_subnet_id
    zones                        = var.availability_zones
    only_critical_addons_enabled = true
    type                         = "VirtualMachineScaleSets"
    os_disk_size_gb              = var.os_disk_size_gb
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    service_cidr      = var.service_cidr
    dns_service_ip    = var.dns_service_ip
    load_balancer_sku = "standard"
  }

  tags = var.tags
}
