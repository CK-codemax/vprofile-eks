variable "env" {
  description = "Environment name."
}

variable "region" {
  description = "AWS region to provision infrastructure."
}

variable "eks_cluster_name" {
  description = "Name of the Amazon EKS cluster."
}

variable "eks_version" {
  description = "Amazon EKS cluster version."
}

variable "general_nodes_ec2_types" {
  description = "EC2 instance type for the general node group."
  type        = list(string)
}

variable "general_nodes_desired_size" {
  description = "Desired size of the general node group."
}

variable "general_nodes_max_size" {
  description = "Maximum size of the general node group."
}

variable "general_nodes_min_size" {
  description = "Minimum size of the general node group."
}

variable "terraform_s3_bucket" {
  type        = string
  description = "An S3 bucket to store the Terraform state."
}

variable "argocd_domain" {
  description = "Domain for ArgoCD ingress."
}

variable "argocd_cert_issuer" {
  description = "Cert-manager cluster issuer for ArgoCD."
}

variable "argocd_cert_secret_name" {
  description = "Secret name for ArgoCD certificate."
}

variable "aws_region" {
  description = "AWS region (for cluster autoscaler)."
}

