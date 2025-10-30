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

variable "argocd_app_repo_url" {
  description = "GitHub repository URL for the ArgoCD application."
  default     = "https://github.com/CK-codemax/argo-project-defs.git"
}

variable "argocd_app_repo_target_revision" {
  description = "Git branch/tag/revision for the ArgoCD application."
  default     = "amazon-eks"
}

variable "argocd_app_source_path" {
  description = "Path within the repository for the application."
  default     = "vprofile"
}

variable "argocd_app_destination_namespace" {
  description = "Destination namespace for the application."
  default     = "vprofile"
}

variable "argocd_project_name" {
  description = "Name of the ArgoCD project."
  default     = "vprofile-project"
}

variable "argocd_app_name" {
  description = "Name of the ArgoCD application."
  default     = "vprofile-app"
}

