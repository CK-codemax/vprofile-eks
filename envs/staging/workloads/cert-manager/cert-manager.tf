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

  # ✅ Reference an external Helm values file
  values = [file("${path.module}/values/cert-manager-values.yaml")]

  # Explicitly disable Prometheus ServiceMonitor to avoid CRD dependency
  set {
    name  = "prometheus.enabled"
    value = "false"
  }

  set {
    name  = "prometheus.servicemonitor.enabled"
    value = "false"
  }

  depends_on = [
    data.terraform_remote_state.eks,
    kubernetes_namespace.cert_manager
  ]
}
