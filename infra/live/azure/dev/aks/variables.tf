variable "project" {
  description = "Project name used for tagging."
  type        = string
}

variable "environment" {
  description = "Environment name used for tagging."
  type        = string
}

variable "cluster_name" {
  description = "The name of the AKS cluster."
  type        = string
}

variable "dns_prefix" {
  description = "DNS prefix for the AKS cluster API server."
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

variable "os_disk_size_gb" {
  description = "OS disk size in GB for system node pool nodes."
  type        = number
  default     = 50
}
