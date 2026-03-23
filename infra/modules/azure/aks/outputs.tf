output "cluster_id" {
  description = "The ID of the AKS cluster."
  value       = azurerm_kubernetes_cluster.main.id
}

output "cluster_name" {
  description = "The name of the AKS cluster."
  value       = azurerm_kubernetes_cluster.main.name
}

output "kube_config_raw" {
  description = "Raw kubeconfig for the AKS cluster."
  value       = azurerm_kubernetes_cluster.main.kube_config_raw
  sensitive   = true
}

output "host" {
  description = "Kubernetes API server endpoint."
  value       = azurerm_kubernetes_cluster.main.kube_config[0].host
  sensitive   = true
}

output "principal_id" {
  description = "Object ID of the cluster's SystemAssigned managed identity. Used for RBAC role assignments."
  value       = azurerm_kubernetes_cluster.main.identity[0].principal_id
}

output "kubelet_identity_object_id" {
  description = "Object ID of the kubelet managed identity. Used for AcrPull role assignment on ACR."
  value       = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
}

output "node_resource_group" {
  description = "Auto-generated resource group containing AKS node VMs and infrastructure."
  value       = azurerm_kubernetes_cluster.main.node_resource_group
}
