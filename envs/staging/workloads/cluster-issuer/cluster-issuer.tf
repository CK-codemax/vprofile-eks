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
                ingressClass = "external-nginx"
              }
            }
          }
        ]
      }
    }
  }

  depends_on = [
    data.terraform_remote_state.cert_manager
  ]
}

