resource "aws_iam_role" "cluster_autoscaler" {
  name = "${var.env}-${var.eks_cluster_name}-cluster-autoscaler"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
        Principal = {
          Service = "pods.eks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "cluster_autoscaler" {
  name = "${var.env}-${var.eks_cluster_name}-cluster-autoscaler"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeScalingActivities",
          "autoscaling:DescribeTags",
          "ec2:DescribeImages",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeLaunchTemplateVersions",
          "ec2:GetInstanceTypesFromInstanceRequirements",
          "eks:DescribeNodegroup"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup"
        ]
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cluster_autoscaler" {
  policy_arn = aws_iam_policy.cluster_autoscaler.arn
  role       = aws_iam_role.cluster_autoscaler.name

  depends_on = [aws_iam_role.cluster_autoscaler, aws_iam_policy.cluster_autoscaler]
}

resource "aws_eks_pod_identity_association" "cluster_autoscaler" {
  cluster_name    = "${var.env}-${var.eks_cluster_name}"
  namespace       = "cluster-autoscaler"
  service_account = "cluster-autoscaler"
  role_arn        = aws_iam_role.cluster_autoscaler.arn

  depends_on = [aws_iam_role.cluster_autoscaler]
}

resource "kubernetes_namespace" "cluster_autoscaler" {
  metadata {
    name = "cluster-autoscaler"
  }

  depends_on = [
    data.aws_eks_cluster.eks,
    data.aws_eks_cluster_auth.eks
  ]
}

resource "helm_release" "cluster_autoscaler" {
  name       = "autoscaler"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  namespace  = kubernetes_namespace.cluster_autoscaler.metadata[0].name
  version    = "9.37.0"
  atomic     = true
  timeout    = 900

  set {
    name  = "rbac.serviceAccount.name"
    value = "cluster-autoscaler"
    type  = "string"
  }

  set {
    name  = "autoDiscovery.clusterName"
    value = "${var.env}-${var.eks_cluster_name}"
    type  = "string"
  }

  set {
    name  = "awsRegion"
    value = var.aws_region
    type  = "string"
  }

  depends_on = [
    data.terraform_remote_state.eks,
    kubernetes_namespace.cluster_autoscaler,
    aws_eks_pod_identity_association.cluster_autoscaler
  ]
}

