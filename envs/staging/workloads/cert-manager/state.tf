terraform {
  backend "s3" {
    region       = ""
    bucket       = ""
    key          = "staging/workloads/cert-manager/terraform.tfstate"
    use_lockfile = true
    encrypt      = true
  }
}

