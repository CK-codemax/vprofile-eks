terraform {
  backend "s3" {
    region       = ""
    bucket       = ""
    key          = "staging/workloads/ebs-csi-driver/terraform.tfstate"
    use_lockfile = true
    encrypt      = true
  }
}

