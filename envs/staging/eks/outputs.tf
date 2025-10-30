output "cluster_security_group_id" {
  description = "Cluster security group that was created by Amazon EKS for the cluster."
  value       = aws_eks_cluster.eks.vpc_config[0].cluster_security_group_id
}

output "cluster_name" {
  description = "Name of the EKS cluster."
  value       = aws_eks_cluster.eks.name
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC provider for the EKS cluster."
  value       = aws_iam_openid_connect_provider.eks.arn
}

output "oidc_provider_url" {
  description = "URL of the OIDC provider for the EKS cluster."
  value       = aws_iam_openid_connect_provider.eks.url
}

