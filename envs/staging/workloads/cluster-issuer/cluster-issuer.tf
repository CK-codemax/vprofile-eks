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
        email  = "admin@ochukowhoro.xyz"
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
    data.terraform_remote_state.cert_manager
  ]
}

