resource "kubernetes_manifest" "vprofile_project" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "AppProject"
    metadata = {
      name      = var.argocd_project_name
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
      name      = var.argocd_app_name
      namespace = "argocd"
    }
    spec = {
      destination = {
        namespace = var.argocd_app_destination_namespace
        server    = "https://kubernetes.default.svc"
      }
      project = var.argocd_project_name
      source = {
        path           = var.argocd_app_source_path
        repoURL        = var.argocd_app_repo_url
        targetRevision = var.argocd_app_repo_target_revision
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

