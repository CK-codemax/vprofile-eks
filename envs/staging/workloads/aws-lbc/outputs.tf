output "namespace" {
  description = "Namespace where aws-lbc is installed."
  value       = kubernetes_namespace.aws_lbc.metadata[0].name
}

output "iam_role_arn" {
  description = "IAM role ARN for AWS Load Balancer Controller."
  value       = aws_iam_role.aws_lbc.arn
}

