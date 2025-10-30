data "aws_iam_policy_document" "ebs_csi_driver" {
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

resource "aws_iam_role" "ebs_csi_driver" {
  name               = "${var.env}-${var.eks_cluster_name}-ebs-csi-driver"
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_driver.json
}

resource "aws_iam_role_policy_attachment" "ebs_csi_driver" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi_driver.name

  depends_on = [aws_iam_role.ebs_csi_driver]
}

resource "aws_iam_policy" "ebs_csi_driver_encryption" {
  name = "${var.env}-${var.eks_cluster_name}-ebs-csi-driver-encryption"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKeyWithoutPlaintext",
          "kms:CreateGrant"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ebs_csi_driver_encryption" {
  policy_arn = aws_iam_policy.ebs_csi_driver_encryption.arn
  role       = aws_iam_role.ebs_csi_driver.name

  depends_on = [aws_iam_role.ebs_csi_driver, aws_iam_policy.ebs_csi_driver_encryption]
}

resource "aws_eks_pod_identity_association" "ebs_csi_driver" {
  cluster_name    = "${var.env}-${var.eks_cluster_name}"
  namespace       = "ebs-csi-driver"
  service_account = "ebs-csi-controller-sa"
  role_arn        = aws_iam_role.ebs_csi_driver.arn

  depends_on = [aws_iam_role.ebs_csi_driver]
}

resource "kubernetes_namespace" "ebs_csi_driver" {
  metadata {
    name = "ebs-csi-driver"
  }

  depends_on = [
    data.aws_eks_cluster.eks,
    data.aws_eks_cluster_auth.eks
  ]
}

resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name             = "${var.env}-${var.eks_cluster_name}"
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = "v1.30.0-eksbuild.1"
  service_account_role_arn = aws_iam_role.ebs_csi_driver.arn

  depends_on = [
    aws_iam_role_policy_attachment.ebs_csi_driver,
    kubernetes_namespace.ebs_csi_driver
  ]
}

