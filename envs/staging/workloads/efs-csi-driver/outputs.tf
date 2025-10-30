output "namespace" {
  description = "Namespace where efs-csi-driver is installed."
  value       = kubernetes_namespace.efs_csi_driver.metadata[0].name
}

output "efs_file_system_id" {
  description = "EFS file system ID."
  value       = aws_efs_file_system.eks.id
}

