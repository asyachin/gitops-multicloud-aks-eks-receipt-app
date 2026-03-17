output "vnet_id" {
  value = azurerm_virtual_network.this.id
}

output "vnet_name" {
  value = azurerm_virtual_network.this.name
}

output "subnet_ids" {
  value = {
    for k, s in azurerm_subnet.this : k => s.id
  }
}

output "subnet_address_prefixes" {
  description = "Map of subnet name => list of address prefixes (CIDRs)."
  value = {
    for k, s in azurerm_subnet.this : k => s.address_prefixes
  }
}

output "subnets" {
  description = "Map of subnet name => subnet attributes (id, name, address_prefixes)."
  value = {
    for k, s in azurerm_subnet.this : k => {
      id               = s.id
      name             = s.name
      address_prefixes = s.address_prefixes
    }
  }
}