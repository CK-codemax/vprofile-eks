# --------------------------
# Declare EKS cluster (data or resource)
# --------------------------

# --------------------------
# Create EFS file system
# --------------------------
resource "aws_efs_file_system" "eks" {
  creation_token = "eks-${var.env}"
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"
  encrypted        = true
}

resource "aws_efs_mount_target" "zone_a" {
  file_system_id  = aws_efs_file_system.eks.id
  subnet_id       = data.terraform_remote_state.vpc.outputs.private_subnet_ids[0]
  security_groups = [data.terraform_remote_state.eks.outputs.cluster_security_group_id]
  depends_on      = [aws_efs_file_system.eks]
}

resource "aws_efs_mount_target" "zone_b" {
  file_system_id  = aws_efs_file_system.eks.id
  subnet_id       = data.terraform_remote_state.vpc.outputs.private_subnet_ids[1]
  security_groups = [data.terraform_remote_state.eks.outputs.cluster_security_group_id]
  depends_on      = [aws_efs_file_system.eks]
}

# --------------------------
# IAM Role for EFS CSI Driver
# --------------------------
data "aws_iam_policy_document" "efs_csi_driver" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(data.terraform_remote_state.eks.outputs.oidc_provider_url, "https://", "")}:sub"
      values   = ["system:serviceaccount:efs-csi-driver:efs-csi-controller-sa"]
    }

    principals {
      identifiers = [data.terraform_remote_state.eks.outputs.oidc_provider_arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "efs_csi_driver" {
  name               = "${var.env}-${var.eks_cluster_name}-efs-csi-driver"
  assume_role_policy = data.aws_iam_policy_document.efs_csi_driver.json
}

resource "aws_iam_role_policy_attachment" "efs_csi_driver" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"
  role       = aws_iam_role.efs_csi_driver.name
}

# --------------------------
# Helm deployment of EFS CSI Driver
# --------------------------
resource "helm_release" "efs_csi_driver" {
  name             = "aws-efs-csi-driver"
  repository       = "https://kubernetes-sigs.github.io/aws-efs-csi-driver/"
  chart            = "aws-efs-csi-driver"
  create_namespace = true
  namespace        = "efs-csi-driver"
  version          = "3.0.3"
  atomic           = true

  set {
    name  = "controller.serviceAccount.create"
    value = "true"
  }

  set {
    name  = "controller.serviceAccount.name"
    value = "efs-csi-controller-sa"
  }

  set {
    name  = "controller.serviceAccount.namespace"
    value = "efs-csi-driver"
  }

  set {
    name  = "controller.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.efs_csi_driver.arn
  }
}

# --------------------------
# EFS StorageClass
# --------------------------
resource "kubernetes_storage_class_v1" "efs" {
  metadata {
    name = "efs"
  }

  storage_provisioner = "efs.csi.aws.com"

  parameters = {
    provisioningMode = "efs-ap"
    fileSystemId     = aws_efs_file_system.eks.id   # <- this is correct now
    directoryPerms   = "700"
  }

  mount_options  = ["iam"]
  reclaim_policy = "Retain"

  depends_on = [helm_release.efs_csi_driver]
}

