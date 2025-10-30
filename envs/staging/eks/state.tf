terraform {
  backend "s3" {
    region       = ""
    bucket       = ""
    key          = "staging/eks/terraform.tfstate"
    use_lockfile = true
    encrypt      = true
  }
}

