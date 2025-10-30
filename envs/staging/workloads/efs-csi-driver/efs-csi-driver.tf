resource "aws_efs_file_system" "eks" {
  creation_token = "eks"

  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"
  encrypted        = true
}

resource "aws_efs_mount_target" "zone_a" {
  file_system_id  = aws_efs_file_system.eks.id
  subnet_id       = data.terraform_remote_state.vpc.outputs.private_subnet_ids[0]
  security_groups = [data.terraform_remote_state.eks.outputs.cluster_security_group_id]

  depends_on = [aws_efs_file_system.eks]
}

resource "aws_efs_mount_target" "zone_b" {
  file_system_id  = aws_efs_file_system.eks.id
  subnet_id       = data.terraform_remote_state.vpc.outputs.private_subnet_ids[1]
  security_groups = [data.terraform_remote_state.eks.outputs.cluster_security_group_id]

  depends_on = [aws_efs_file_system.eks]
}

data "aws_iam_policy_document" "efs_csi_driver" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(data.terraform_remote_state.eks.outputs.oidc_provider_url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:efs-csi-controller-sa"]
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

resource "kubernetes_namespace" "efs_csi_driver" {
  metadata {
    name = "efs-csi-driver"
  }

  depends_on = [
    data.aws_eks_cluster.eks,
    data.aws_eks_cluster_auth.eks
  ]
}

resource "helm_release" "efs_csi_driver" {
  name       = "aws-efs-csi-driver"
  repository = "https://kubernetes-sigs.github.io/aws-efs-csi-driver/"
  chart      = "aws-efs-csi-driver"
  namespace  = kubernetes_namespace.efs_csi_driver.metadata[0].name
  version    = "3.0.3"
  atomic     = true

  set {
    name  = "controller.serviceAccount.name"
    value = "efs-csi-controller-sa"
  }

  set {
    name  = "controller.serviceAccount.namespace"
    value = "kube-system"
  }

  set {
    name  = "controller.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.efs_csi_driver.arn
  }

  depends_on = [
    aws_efs_mount_target.zone_a,
    aws_efs_mount_target.zone_b,
    kubernetes_namespace.efs_csi_driver
  ]
}

resource "kubernetes_storage_class_v1" "efs" {
  metadata {
    name = "efs"
  }

  storage_provisioner = "efs.csi.aws.com"

  parameters = {
    provisioningMode = "efs-ap"
    fileSystemId     = aws_efs_file_system.eks.id
    directoryPerms   = "700"
  }

  mount_options = ["iam"]

  depends_on = [helm_release.efs_csi_driver]
}

