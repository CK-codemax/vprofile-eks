terraform {
  backend "s3" {
    region       = ""
    bucket       = ""
    key          = "staging/workloads/argocd-ingress/terraform.tfstate"
    use_lockfile = true
    encrypt      = true
  }
}

