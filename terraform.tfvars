# ==============================================================================
# Global/Common Variables
# ==============================================================================
env                 = "staging"
region              = "us-west-2"
terraform_s3_bucket = "vprofile-move35623-add-terraform-state"
eks_cluster_name    = "demo3"
aws_region          = "us-west-2"

# ==============================================================================
# S3 Backend Variables
# ==============================================================================
bucket = "vprofile-move35623-add-terraform-state"

# ==============================================================================
# VPC Variables
# ==============================================================================
vpc_cidr             = "10.0.0.0/16"
az1                  = "us-west-2a"
az2                  = "us-west-2b"
private_subnet1_cidr = "10.0.0.0/19"
private_subnet2_cidr = "10.0.32.0/19"
public_subnet1_cidr  = "10.0.64.0/19"
public_subnet2_cidr  = "10.0.96.0/19"

# ==============================================================================
# EKS Cluster Variables
# ==============================================================================
eks_version            = "1.29"
general_nodes_ec2_types  = ["t3.large"]
general_nodes_desired_size = 1
general_nodes_max_size   = 10
general_nodes_min_size   = 0

# ==============================================================================
# ArgoCD Variables
# ==============================================================================
argocd_domain           = "argo.ochukowhoro.xyz"
argocd_cert_issuer      = "http-01-production"
argocd_cert_secret_name = "argo-ochukowhoro-xyz"

# ==============================================================================
# ArgoCD Application Variables
# ==============================================================================
argocd_app_repo_url            = "https://github.com/CK-codemax/argo-project-defs.git"
argocd_app_repo_target_revision = "amazon-eks"
argocd_app_source_path         = "vprofile"
argocd_app_destination_namespace = "vprofile"
argocd_project_name            = "vprofile-project"
argocd_app_name                = "vprofile-app"

