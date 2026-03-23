variable "cluster_name" {
  description = "The name of the AKS cluster."
  type        = string
}

variable "location" {
  description = "Azure region where the cluster will be created."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group for the AKS cluster."
  type        = string
}

variable "dns_prefix" {
  description = "DNS prefix for the AKS cluster."
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version. Null means latest stable."
  type        = string
  default     = null
}

variable "automatic_channel_upgrade" {
  description = "Automatic upgrade channel: patch, rapid, node-image, stable, or none."
  type        = string
  default     = "patch"
}

variable "azure_policy_enabled" {
  description = "Whether to enable Azure Policy add-on."
  type        = bool
  default     = false
}

variable "system_node_count" {
  description = "Number of nodes in the system node pool."
  type        = number
  default     = 1
}

variable "system_vm_size" {
  description = "VM size for the system node pool."
  type        = string
  default     = "Standard_D2s_v3"
}

variable "system_subnet_id" {
  description = "Subnet ID for the system node pool (subnet-aks-system)."
  type        = string
}

variable "availability_zones" {
  description = "List of availability zones for the system node pool."
  type        = list(string)
  default     = []
}

variable "os_disk_size_gb" {
  description = "OS disk size in GB for system node pool nodes."
  type        = number
  default     = 50
}

variable "service_cidr" {
  description = "CIDR range for Kubernetes services. Must not overlap with VNet address space."
  type        = string
  default     = "172.16.0.0/16"
}

variable "dns_service_ip" {
  description = "IP address within service_cidr used for DNS. Typically .10 of service_cidr."
  type        = string
  default     = "172.16.0.10"
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}
