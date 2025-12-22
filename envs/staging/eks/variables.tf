variable "env" {
  description = "Environment name."
}

variable "region" {
  description = "AWS region to provision infrastructure."
}

variable "eks_cluster_name" {
  description = "Name of the Amazon EKS cluster."
}

variable "terraform_s3_bucket" {
  type        = string
  description = "An S3 bucket to store the Terraform state."
}

variable "eks_admin_policy_name" {
  description = "Name of the IAM policy for EKS admin access."
  type        = string
}

variable "manager_user_name" {
  description = "Name of the IAM user for manager role."
  type        = string
}

variable "eks_assume_admin_policy_name" {
  description = "Name of the IAM policy for assuming EKS admin role."
  type        = string
}

variable "developer_user_name" {
  description = "Name of the IAM user for developer role."
  type        = string
}

variable "developer_eks_policy_name" {
  description = "Name of the IAM policy for EKS developer access."
  type        = string
}

variable "aws_region" {
  description = "AWS region (for cluster autoscaler)."
}

variable "eks_cluster_role_name" {
  description = "Name of the IAM role for the EKS cluster."
  type        = string
}

variable "eks_admin_role_name" {
  description = "Name of the IAM role for EKS admin access."
  type        = string
}

variable "eks_nodes_role_name" {
  description = "Name of the IAM role for EKS worker nodes."
  type        = string
}

