output "namespace" {
  description = "Namespace where cert-manager is installed."
  value       = kubernetes_namespace.cert_manager.metadata[0].name
}

