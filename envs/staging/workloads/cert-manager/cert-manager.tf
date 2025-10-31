##############################################################
# 1️⃣ Namespace for cert-manager
##############################################################
resource "kubernetes_namespace" "cert_manager" {
  metadata {
    name = "cert-manager"
  }

  depends_on = [
    data.aws_eks_cluster.eks,
    data.aws_eks_cluster_auth.eks
  ]
}

##############################################################
# 2️⃣ Helm release for cert-manager
##############################################################
resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  namespace        = kubernetes_namespace.cert_manager.metadata[0].name
  create_namespace = true
  version          = "v1.14.5"
  atomic           = true
  timeout          = 900

  # Ensure CRDs are installed
  set {
    name  = "installCRDs"
    value = "true"
  }

  # ✅ Set the resource requests for ACME HTTP-01 solver to meet cluster limits
  set {
    name  = "extraArgs[0]"
    value = "--acme-http01-solver-resource-requests-cpu=50m"
  }

  set {
    name  = "extraArgs[1]"
    value = "--acme-http01-solver-resource-requests-memory=64Mi"
  }

  depends_on = [
    data.terraform_remote_state.eks,
    kubernetes_namespace.cert_manager
  ]
}
