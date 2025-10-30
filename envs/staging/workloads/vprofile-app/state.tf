terraform {
  backend "s3" {
    region       = ""
    bucket       = ""
    key          = "staging/workloads/vprofile-app/terraform.tfstate"
    use_lockfile = true
    encrypt      = true
  }
}

