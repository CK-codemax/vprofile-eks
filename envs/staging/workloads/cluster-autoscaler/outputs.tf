output "namespace" {
  description = "Namespace where cluster-autoscaler is installed."
  value       = kubernetes_namespace.cluster_autoscaler.metadata[0].name
}

output "iam_role_arn" {
  description = "IAM role ARN for cluster autoscaler."
  value       = aws_iam_role.cluster_autoscaler.arn
}

