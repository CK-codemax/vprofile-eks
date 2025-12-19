data "aws_iam_policy_document" "aws_lbc" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }

    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]
  }
}

resource "aws_iam_role" "aws_lbc" {
  name               = "${var.env}-${var.eks_cluster_name}-aws-lbc"
  assume_role_policy = data.aws_iam_policy_document.aws_lbc.json
}

resource "aws_iam_policy" "aws_lbc" {
  policy = file("${path.module}/iam/AWSLoadBalancerController.json")
  name   = "AWSLoadBalancerController"
}

resource "aws_iam_role_policy_attachment" "aws_lbc" {
  policy_arn = aws_iam_policy.aws_lbc.arn
  role       = aws_iam_role.aws_lbc.name

  depends_on = [aws_iam_role.aws_lbc, aws_iam_policy.aws_lbc]
}

resource "aws_eks_pod_identity_association" "aws_lbc" {
  cluster_name    = "${var.env}-${var.eks_cluster_name}"
  namespace       = "aws-load-balancer-controller"
  service_account = "aws-load-balancer-controller"
  role_arn        = aws_iam_role.aws_lbc.arn

  depends_on = [aws_iam_role.aws_lbc]
}

resource "kubernetes_namespace" "aws_lbc" {
  metadata {
    name = "aws-load-balancer-controller"
  }

  depends_on = [
    data.aws_eks_cluster.eks,
    data.aws_eks_cluster_auth.eks
  ]
}

resource "helm_release" "aws_lbc" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = kubernetes_namespace.aws_lbc.metadata[0].name
  version    = "1.7.2"
  atomic     = true
  timeout    = 900

  set {
    name  = "clusterName"
    value = "${var.env}-${var.eks_cluster_name}"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "vpcId"
    value = data.terraform_remote_state.vpc.outputs.vpc_id
  }

  depends_on = [
    data.terraform_remote_state.eks,
    data.terraform_remote_state.vpc,
    kubernetes_namespace.aws_lbc,
    aws_eks_pod_identity_association.aws_lbc
  ]
}

