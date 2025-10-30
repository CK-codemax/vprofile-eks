data "aws_eks_cluster" "eks" {
  name = aws_eks_cluster.eks.name

  depends_on = [aws_eks_cluster.eks]
}

data "aws_eks_cluster_auth" "eks" {
  name = aws_eks_cluster.eks.name

  depends_on = [aws_eks_cluster.eks]
}

data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = var.terraform_s3_bucket
    key    = "staging/vpc/terraform.tfstate"
    region = var.region
  }
}

data "aws_caller_identity" "current" {}

