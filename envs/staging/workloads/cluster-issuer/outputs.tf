output "cluster_issuer_name" {
  description = "Name of the ClusterIssuer resource."
  value       = kubernetes_manifest.http01_production_cluster_issuer.manifest.metadata.name
}

