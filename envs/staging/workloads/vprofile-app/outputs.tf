output "project_name" {
  description = "Name of the ArgoCD project."
  value       = kubernetes_manifest.vprofile_project.manifest.metadata.name
}

output "app_name" {
  description = "Name of the ArgoCD application."
  value       = kubernetes_manifest.vprofile_app.manifest.metadata.name
}

output "app_namespace" {
  description = "Namespace where the application is deployed."
  value       = kubernetes_manifest.vprofile_app.manifest.spec.destination.namespace
}

