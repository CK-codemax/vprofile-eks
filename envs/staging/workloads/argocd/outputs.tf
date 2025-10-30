output "namespace" {
  description = "Namespace where argocd is installed."
  value       = kubernetes_namespace.argocd.metadata[0].name
}

