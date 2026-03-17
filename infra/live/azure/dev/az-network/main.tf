locals {
  tags = {
    project     = var.project
    environment = var.environment
  }
}

resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.location
  tags     = local.tags
}

module "vnet" {
  source                  = "../../../../modules/azure/vnet"
  resource_group_name     = azurerm_resource_group.this.name
  name                    = var.name
  location                = azurerm_resource_group.this.location
  address_space           = var.address_space
  subnets                 = var.subnets
  tags                    = local.tags
  dns_servers             = var.dns_servers
  ddos_protection_plan_id = var.ddos_protection_plan_id
  enable_ddos_protection  = var.enable_ddos_protection
}
