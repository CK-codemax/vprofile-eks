resource "kubernetes_namespace" "metrics_server" {
  metadata {
    name = "metrics-server"
  }

  depends_on = [
    data.aws_eks_cluster.eks,
    data.aws_eks_cluster_auth.eks
  ]
}

resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  namespace  = kubernetes_namespace.metrics_server.metadata[0].name
  version    = "3.12.1"
  atomic     = true
  timeout    = 900

  values = [file("${path.module}/values/metrics-server.yaml")]

  depends_on = [
    data.terraform_remote_state.eks,
    kubernetes_namespace.metrics_server
  ]
}

