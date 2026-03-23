output "vnet_id" {
  description = "The ID of the virtual network."
  value       = module.vnet.vnet_id
}

output "vnet_name" {
  description = "The name of the virtual network."
  value       = module.vnet.vnet_name
}

output "subnet_ids" {
  description = "Map of subnet name => subnet ID."
  value       = module.vnet.subnet_ids
}

output "subnet_address_prefixes" {
  description = "Map of subnet name => list of address prefixes (CIDRs)."
  value       = module.vnet.subnet_address_prefixes
}

output "subnets" {
  description = "Map of subnet name => subnet attributes (id, name, address_prefixes)."
  value       = module.vnet.subnets
}

output "resource_group_name" {
  description = "The name of the resource group."
  value       = azurerm_resource_group.this.name
}

output "resource_group_id" {
  description = "The ID of the resource group."
  value       = azurerm_resource_group.this.id
}

output "resource_group_location" {
  description = "The Azure region where resources are deployed."
  value       = azurerm_resource_group.this.location
}

output "availability_zones" {
  description = "Availability zones used in this environment. Referenced by AKS node pools, LB, and other zonal resources."
  value       = local.availability_zones
}