##############################################################
# Wait for cert-manager CRDs to be established
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
    data.terraform_remote_state.cert_manager
  ]
}

##############################################################
# ClusterIssuer for Let's Encrypt Production
##############################################################
resource "kubernetes_manifest" "http01_production_cluster_issuer" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "http-01-production"
    }
    spec = {
      acme = {
        email  = var.cert_manager_email
        server = "https://acme-v02.api.letsencrypt.org/directory"
        privateKeySecretRef = {
          name = "http-01-production-cluster-issuer"
        }
        solvers = [
          {
            http01 = {
              ingress = {
                ingressClassName = "external-nginx"
              }
            }
          }
        ]
      }
    }
  }

  depends_on = [
    data.terraform_remote_state.cert_manager,
    null_resource.wait_for_cert_manager_crds
  ]
}

