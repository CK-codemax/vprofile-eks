resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }

  depends_on = [
    data.aws_eks_cluster.eks,
    data.aws_eks_cluster_auth.eks
  ]
}

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = kubernetes_namespace.argocd.metadata[0].name
  create_namespace = true
  atomic           = true
  timeout          = 900

  values = [file("${path.module}/values/argocd-values.yml")]

  depends_on = [
    data.terraform_remote_state.eks,
    kubernetes_namespace.argocd
  ]
}

