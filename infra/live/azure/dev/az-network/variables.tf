variable "resource_group_name" {
  type        = string
  description = "The name of the resource group"
}

variable "name" {
  type        = string
  description = "The name of the virtual network"
}

variable "location" {
  type        = string
  description = "The location of the virtual network"
}

variable "address_space" {
  type        = list(string)
  description = "The address space of the virtual network"
}

variable "subnets" {
  description = "The subnets of the virtual network"
  type = map(object({
    address_prefixes  = list(string)
    service_endpoints = list(string)
  }))
}

variable "project" {
  type        = string
  description = "The project name"
}

variable "environment" {
  type        = string
  description = "The environment name"
}

variable "dns_servers" {
  description = "The DNS servers of the virtual network"
  type        = list(string)
  default     = []
}

variable "ddos_protection_plan_id" {
  description = "The ID of the DDoS protection plan"
  type        = string
  default     = null
}

variable "enable_ddos_protection" {
  description = "Whether to enable DDoS protection"
  type        = bool
  default     = false
}


