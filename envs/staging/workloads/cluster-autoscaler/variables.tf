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

variable "aws_region" {
  description = "AWS region (for cluster autoscaler)."
}

