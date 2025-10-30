data "terraform_remote_state" "eks" {
  backend = "s3"
  config = {
    bucket = var.terraform_s3_bucket
    key    = "staging/eks/terraform.tfstate"
    region = var.region
  }
}

data "aws_eks_cluster" "eks" {
  name = "${var.env}-${var.eks_cluster_name}"
}

data "aws_eks_cluster_auth" "eks" {
  name = "${var.env}-${var.eks_cluster_name}"
}

