resource "kubernetes_manifest" "vprofile_project" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "AppProject"
    metadata = {
      name      = "vprofile-project"
      namespace = "argocd"
    }
    spec = {
      description = "VProfile Application Project"
      sourceRepos = ["*"]
      destinations = [
        {
          namespace = "*"
          server    = "*"
        }
      ]
      clusterResourceWhitelist = [
        {
          group = "*"
          kind  = "*"
        }
      ]
    }
  }

  depends_on = [
    data.aws_eks_cluster.eks,
    data.aws_eks_cluster_auth.eks
  ]
}

resource "kubernetes_manifest" "vprofile_app" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "vprofile-app"
      namespace = "argocd"
    }
    spec = {
      destination = {
        namespace = "vprofile"
        server    = "https://kubernetes.default.svc"
      }
      project = "vprofile-project"
      source = {
        path           = "vprofile"
        repoURL        = "https://github.com/OchukoWH/argo-project-defs.git"
        targetRevision = "amazon-eks"
      }
      syncPolicy = {
        automated = {
          prune   = true
          selfHeal = true
        }
        syncOptions = ["CreateNamespace=true"]
      }
    }
  }

  depends_on = [
    data.aws_eks_cluster.eks,
    data.aws_eks_cluster_auth.eks,
    kubernetes_manifest.vprofile_project
  ]
}

