##############################################################
# 1️⃣ IAM Role for the EBS CSI Driver (IRSA)
##############################################################
data "aws_iam_policy_document" "ebs_csi_driver_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = [data.terraform_remote_state.eks.outputs.oidc_provider_arn]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "${replace(data.terraform_remote_state.eks.outputs.oidc_provider_url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }
  }
}

resource "aws_iam_role" "ebs_csi_driver" {
  name               = "${var.env}-${var.eks_cluster_name}-ebs-csi-driver"
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_driver_assume_role.json
}

# Attach the AWS-managed EBS CSI Driver Policy
resource "aws_iam_role_policy_attachment" "ebs_csi_driver_policy" {
  role       = aws_iam_role.ebs_csi_driver.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

##############################################################
# 2️⃣ Kubernetes Service Account (IRSA)
##############################################################
resource "kubernetes_service_account" "ebs_csi_controller" {
  metadata {
    name      = "ebs-csi-controller-sa"
    namespace = "kube-system"

    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.ebs_csi_driver.arn
    }
  }
}

##############################################################
# 3️⃣ EKS Addon for AWS EBS CSI Driver
##############################################################
resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name             = data.aws_eks_cluster.eks.name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = "v1.30.0-eksbuild.1"
  service_account_role_arn = aws_iam_role.ebs_csi_driver.arn

  depends_on = [
    aws_iam_role_policy_attachment.ebs_csi_driver_policy,
    kubernetes_service_account.ebs_csi_controller
  ]
}

##############################################################
# 4️⃣ Default StorageClass for EBS CSI
##############################################################
resource "kubernetes_storage_class_v1" "ebs_gp3" {
  metadata {
    name = "ebs-gp3"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }

  storage_provisioner     = "ebs.csi.aws.com"
  reclaim_policy          = "Delete"
  volume_binding_mode     = "WaitForFirstConsumer"
  allow_volume_expansion  = true

  parameters = {
    type   = "gp3"
    fsType = "ext4"
  }

  depends_on = [
    aws_eks_addon.ebs_csi_driver
  ]
}

