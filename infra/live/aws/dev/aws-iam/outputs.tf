output "cluster_role_arn" {
  description = "The ARN of the EKS cluster role"
  value       = aws_iam_role.eks_cluster.arn
}

output "node_group_role_arn" {
  description = "The ARN of the EKS node group role"
  value       = aws_iam_role.eks_node_group.arn
}
