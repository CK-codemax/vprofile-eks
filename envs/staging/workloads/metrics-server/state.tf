terraform {
  backend "s3" {
    region       = ""
    bucket       = ""
    key          = "staging/workloads/metrics-server/terraform.tfstate"
    use_lockfile = true
    encrypt      = true
  }
}

