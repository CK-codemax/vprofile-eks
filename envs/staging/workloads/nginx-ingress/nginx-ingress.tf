resource "kubernetes_namespace" "nginx_ingress" {
  metadata {
    name = "ingress-nginx"
  }

  depends_on = [
    data.aws_eks_cluster.eks,
    data.aws_eks_cluster_auth.eks
  ]
}

resource "helm_release" "external_nginx" {
  name             = "external-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = kubernetes_namespace.nginx_ingress.metadata[0].name
  create_namespace = true
  version          = "4.10.1"
  atomic           = true
  timeout          = 900
  values = [file("${path.module}/values/nginx-ingress.yaml")]

  depends_on = [
    data.terraform_remote_state.eks,
    kubernetes_namespace.nginx_ingress
  ]
}
