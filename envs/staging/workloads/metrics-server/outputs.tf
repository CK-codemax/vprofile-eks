output "namespace" {
  description = "Namespace where metrics-server is installed."
  value       = kubernetes_namespace.metrics_server.metadata[0].name
}

output "release_name" {
  description = "Name of the Helm release."
  value       = helm_release.metrics_server.name
}

