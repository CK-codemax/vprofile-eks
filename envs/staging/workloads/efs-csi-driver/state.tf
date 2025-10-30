terraform {
  backend "s3" {
    region       = ""
    bucket       = ""
    key          = "staging/workloads/efs-csi-driver/terraform.tfstate"
    use_lockfile = true
    encrypt      = true
  }
}

