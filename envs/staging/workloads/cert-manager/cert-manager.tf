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

  depends_on = [
    data.terraform_remote_state.eks,
    kubernetes_namespace.cert_manager
  ]
}

##############################################################
# 3️⃣ Wait for cert-manager CRDs before applying manifests
##############################################################
resource "null_resource" "wait_for_cert_manager_crds" {
  provisioner "local-exec" {
    command = <<-EOT
      echo "Waiting for cert-manager CRDs to be established..."
      for i in {1..30}; do
        if kubectl get crd clusterissuers.cert-manager.io >/dev/null 2>&1; then
          echo "✅ cert-manager CRDs are ready!"
          exit 0
        fi
        echo "⏳ Waiting for CRDs... retry $i/30"
        sleep 10
      done
      echo "❌ Timeout waiting for cert-manager CRDs" && exit 1
    EOT
  }

  depends_on = [
    helm_release.cert_manager
  ]
}
