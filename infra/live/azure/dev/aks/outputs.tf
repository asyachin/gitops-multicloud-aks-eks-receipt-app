output "cluster_id" {
  description = "The ID of the AKS cluster."
  value       = module.aks.cluster_id
}

output "cluster_name" {
  description = "The name of the AKS cluster."
  value       = module.aks.cluster_name
}

output "kube_config_raw" {
  description = "Raw kubeconfig for the AKS cluster."
  value       = module.aks.kube_config_raw
  sensitive   = true
}

output "host" {
  description = "Kubernetes API server endpoint."
  value       = module.aks.host
  sensitive   = true
}

output "principal_id" {
  description = "Object ID of the cluster's SystemAssigned managed identity."
  value       = module.aks.principal_id
}

output "kubelet_identity_object_id" {
  description = "Object ID of the kubelet identity. Used for AcrPull role assignment."
  value       = module.aks.kubelet_identity_object_id
}

output "node_resource_group" {
  description = "Auto-generated resource group containing AKS node infrastructure."
  value       = module.aks.node_resource_group
}
