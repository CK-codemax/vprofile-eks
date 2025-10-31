terraform {
  backend "s3" {
    region       = ""
    bucket       = ""
    key          = "staging/workloads/cluster-issuer/terraform.tfstate"
    use_lockfile = true
    encrypt      = true
  }
}

