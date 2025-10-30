terraform {
  backend "s3" {
    region       = ""
    bucket       = ""
    key          = "staging/workloads/aws-lbc/terraform.tfstate"
    use_lockfile = true
    encrypt      = true
  }
}

