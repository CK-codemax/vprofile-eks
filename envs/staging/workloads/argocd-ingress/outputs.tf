output "ingress_name" {
  description = "Name of the ArgoCD ingress resource."
  value       = kubernetes_manifest.argocd_ingress.manifest.metadata.name
}

output "ingress_namespace" {
  description = "Namespace of the ArgoCD ingress resource."
  value       = kubernetes_manifest.argocd_ingress.manifest.metadata.namespace
}

