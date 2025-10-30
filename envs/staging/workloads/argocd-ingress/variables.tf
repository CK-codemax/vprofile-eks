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
  description = "Domain for ArgoCD ingress."
}

variable "argocd_cert_issuer" {
  description = "Cert-manager cluster issuer for ArgoCD."
}

variable "argocd_cert_secret_name" {
  description = "Secret name for ArgoCD certificate."
}

variable "cert_manager_email" {
  description = "Email address used for Let's Encrypt registration."
  type        = string
}
