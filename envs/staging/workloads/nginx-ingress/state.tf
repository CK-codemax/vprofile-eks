terraform {
  backend "s3" {
    region       = ""
    bucket       = ""
    key          = "staging/workloads/nginx-ingress/terraform.tfstate"
    use_lockfile = true
    encrypt      = true
  }
}

