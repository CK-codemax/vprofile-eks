variable "region" {
  description = "AWS region to provision infrastructure."
}

variable "terraform_s3_bucket" {
  type        = string
  description = "An S3 bucket to store the Terraform state."
}

variable "env" {
  description = "Environment name."
}

variable "eks_cluster_name" {
  description = "Name of the Amazon EKS cluster."
}

variable "argocd_domain" {
  description = "Domain name for ArgoCD ingress (e.g., argo.example.com)."
  type        = string
}

