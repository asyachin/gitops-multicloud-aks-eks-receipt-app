

variable "resource_group_name" {
    type = string
    description = "The name of the resource group"
}

variable "name" {
    type = string
    description = "The name of the virtual network"
}

variable "location" {
    type = string
    description = "The location of the virtual network"
}

variable "address_space" {
    type = list(string)
    description = "The address space of the virtual network"
}

variable "subnets" {
    description = "The subnets of the virtual network"
    type = map(object({
        address_prefixes = list(string)
        service_endpoints = list(string)

        delegations = optional(list(object({
            name = string
            service_delegation = object({
                name = string
                actions = list(string)
      })
    })), [])

    private_endpoint_network_policies = optional(string, "Enabled")
    private_link_service_network_policies_enabled = optional(bool, true)

    }))
}

variable "tags" {
    description = "The tags of the virtual network"
    type = map(string)
    default = {}
}

variable "dns_servers" {
    description = "The DNS servers of the virtual network"
    type = list(string)
    default = []
}

variable "ddos_protection_plan_id" {
    description = "The ID of the DDoS protection plan"
    type = string
    default = null
}

variable "enable_ddos_protection" {
    type = bool
    default = false
}
