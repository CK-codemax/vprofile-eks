output "namespace" {
  description = "Namespace where ebs-csi-driver is installed."
  value       = kubernetes_namespace.ebs_csi_driver.metadata[0].name
}

output "iam_role_arn" {
  description = "IAM role ARN for EBS CSI driver."
  value       = aws_iam_role.ebs_csi_driver.arn
}

