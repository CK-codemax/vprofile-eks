terraform {
  backend "s3" {
    region       = ""
    bucket       = ""
    key          = "staging/vpc/terraform.tfstate"
    use_lockfile = true
    encrypt      = true
  }
}

