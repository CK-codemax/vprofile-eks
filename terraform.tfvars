# ==============================================================================
# Global/Common Variables
# ==============================================================================
env                 = "staging"
region              = "us-east-2"
terraform_s3_bucket = "vprofile-ochuko"
eks_cluster_name    = "demo3"
aws_region          = "us-east-2"

# ==============================================================================
# S3 Backend Variables
# ==============================================================================
bucket = "vprofile-ochuko"

# ==============================================================================
# IAM Variables
# ==============================================================================
eks_admin_policy_name        = "AmazonEKSAdminPolicy3"
manager_user_name            = "manager3"
eks_assume_admin_policy_name = "AmazonEKSAssumeAdminPolicy3"
developer_user_name          = "developer3"
developer_eks_policy_name    = "AmazonEKSDeveloperPolicy3"
aws_lbc_policy_name          = "AWSLoadBalancerController3"

# IAM Role Name Variables
eks_cluster_role_name = "staging-demo3-eks-cluster"
eks_admin_role_name   = "staging-demo3-eks-admin"
eks_nodes_role_name   = "staging-demo3-eks-nodes"

