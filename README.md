# VProfile EKS Infrastructure

This project deploys a complete AWS EKS (Elastic Kubernetes Service) cluster with supporting infrastructure using Terraform.

## Architecture

This project creates:
- **S3 Backend**: Terraform state storage with versioning and encryption
- **VPC**: Virtual Private Cloud with public and private subnets across 2 availability zones
- **Networking**: Internet Gateway, NAT Gateway, and route tables
- **EKS Cluster**: Managed Kubernetes cluster with worker nodes
- **Add-ons**: Pod Identity, Metrics Server, Cluster Autoscaler
- **Load Balancing**: AWS Load Balancer Controller
- **Ingress**: Nginx Ingress Controller
- **Certificates**: Cert-Manager for TLS certificates
- **Storage**: EBS and EFS CSI drivers
- **GitOps**: ArgoCD for continuous deployment

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) >= 1.0
- [AWS CLI](https://aws.amazon.com/cli/) installed and configured with appropriate credentials
- AWS account with permissions to create EKS clusters, VPCs, and related resources
- [kubectl](https://kubernetes.io/docs/tasks/tools/) installed and configured
- [Helm](https://helm.sh/docs/intro/install/) 3.x installed (for ArgoCD helm chart)

## Configuration

This project uses a unified `terraform.tfvars` file at the root level (`terraform.tfvars`) that contains all configuration variables for all modules. This simplifies management and ensures consistency across all modules.

**Unified configuration file:**
- **Root**: `terraform.tfvars` - Contains all variables for all modules organized by section

**To modify configuration values:**
- Edit the root `terraform.tfvars` file
- All modules will use variables from this unified file

**Default values:**
- **Environment**: staging
- **Region**: us-west-2
- **EKS Cluster Name**: demo3 (full name: staging-demo3)
- **EKS Version**: 1.29
- **Availability Zones**: us-west-2a, us-west-2b
- **S3 Bucket**: vprofile-move35623-add-terraform-state

## Deployment

This project uses a Makefile for simplified deployment. See available targets with `make help`.

### Quick Start

```bash
# 1. Initialize S3 backend (first time only)
make init-s3
make deploy-s3

# 2. Deploy infrastructure (VPC + EKS)
make deploy-infrastructure

# 3. Update kubectl config
make update-kubeconfig

# 4. Verify cluster access
make verify-cluster

# 5. Deploy all workloads
make deploy-workloads

# Or deploy everything at once:
make deploy-all
```

### Available Make Targets

**Infrastructure:**
- `make init-s3` - Initialize S3 backend (first time only)
- `make deploy-s3` - Deploy S3 backend
- `make deploy-vpc` - Deploy VPC infrastructure
- `make deploy-eks` - Deploy EKS cluster
- `make deploy-infrastructure` - Deploy VPC and EKS sequentially

**Workloads:**
- `make deploy-workloads` - Deploy all workloads sequentially
- `make deploy-all` - Deploy infrastructure + workloads

**Planning:**
- `make plan-vpc` - Plan VPC changes
- `make plan-eks` - Plan EKS changes
- `make plan-workloads` - Plan all workload changes

**Destruction:**
- `make destroy-workloads` - Destroy all workloads (reverse order)
- `make destroy-infrastructure` - Destroy VPC and EKS
- `make destroy-all` - Destroy everything

**Utilities:**
- `make update-kubeconfig` - Update kubectl config for cluster
- `make verify-cluster` - Verify cluster access
- `make clean` - Clean Terraform plan files

### Manual Deployment (Alternative)

If you prefer to deploy manually or need more control, you can use Terraform commands directly:

**Step 1: Initialize and Create S3 Backend**

```bash
cd envs/global/s3
terraform init
terraform apply -var-file=../../../terraform.tfvars
terraform init -migrate-state -backend-config=../../../state.config
```

**Step 2: Deploy VPC**

```bash
cd ../../staging/vpc
terraform init -backend-config=../../../state.config
terraform plan -var-file=../../../terraform.tfvars
terraform apply -var-file=../../../terraform.tfvars
```

**Step 3: Deploy EKS Cluster**

```bash
cd ../eks
terraform init -backend-config=../../../state.config
terraform plan -var-file=../../../terraform.tfvars
terraform apply -var-file=../../../terraform.tfvars
```

**Step 4: Configure kubectl**

```bash
aws eks update-kubeconfig --name staging-demo3 --region us-west-2
kubectl get nodes
```

**Step 5: Deploy Workloads**

Each workload follows the same pattern:
```bash
cd envs/staging/workloads/<workload-name>
terraform init -backend-config=../../../../state.config
terraform apply -var-file=../../../../terraform.tfvars
```

Workloads must be deployed in order:
1. metrics-server
2. cluster-autoscaler
3. aws-lbc
4. nginx-ingress
5. cert-manager
6. ebs-csi-driver
7. efs-csi-driver
8. argocd
9. argocd-ingress
10. vprofile-app

### Step 7: Install ArgoCD CLI and Access ArgoCD

```bash
# Install ArgoCD CLI (macOS)
brew install argocd

# Install ArgoCD CLI (Linux)
curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
chmod +x /usr/local/bin/argocd

# Port forward to access ArgoCD server locally (HTTP)
kubectl port-forward svc/argocd-server 8080:80 -n argocd

# Get ArgoCD admin password (in a new terminal)
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo

# Login to ArgoCD CLI (while port-forward is running)
argocd login localhost:8080 --username admin --insecure --grpc-web

# Update ArgoCD admin password (optional but recommended)
argocd account update-password
```

### Step 8: Access ArgoCD via Ingress

The ArgoCD ingress should be accessible at: `https://argo.ochukowhoro.xyz`

```bash
# Check ingress status
kubectl get ingress -n argocd

# Check certificate status
kubectl get certificate -n argocd

# Verify certificate is issued
kubectl describe certificate -n argocd
```

## Verification Commands

```bash
# Check all EKS add-ons
kubectl get addons -A

# Check ArgoCD pods
kubectl get pods -n argocd

# Check ArgoCD application controller logs
kubectl logs -f argocd-application-controller-0 -n argocd

# Check all resources in cluster
kubectl get all --all-namespaces

# Check node groups
aws eks describe-nodegroup --cluster-name staging-demo3 --nodegroup-name general --region us-west-2
```

## AWS CLI and kubectl Commands

### AWS Profile Configuration

```bash
# Configure AWS profile for developer
aws configure --profile developer

# List all configured AWS profiles
aws configure list-profiles

# Verify current AWS identity
aws sts get-caller-identity
```

### kubectl Configuration

```bash
# Update kubeconfig with specific profile
aws eks update-kubeconfig \
  --region us-west-2 \
  --name staging-demo3 \
  --profile developer

# Update kubeconfig without profile (uses default credentials)
aws eks update-kubeconfig \
  --region us-west-2 \
  --name staging-demo3

# View full kubectl configuration
kubectl config view

# View minimal kubectl configuration (current context only)
kubectl config view --minify
```

### IAM Role Assumption

```bash
# Assume IAM role for manager access
aws sts assume-role \
  --role-arn arn:aws:iam::424432388155:role/staging-demo3-eks-admin \
  --role-session-name manager-session \
  --profile manager
```

### EKS Add-on Management

```bash
# List available versions for Pod Identity addon
aws eks describe-addon-versions \
  --region us-west-2 \
  --addon-name eks-pod-identity-agent
```

### Testing Application Endpoints

```bash
# Test application endpoint (direct ELB URL)
curl -i http://k8s-5example-myapp-7983349254-55ccfb35729f9d5c.elb.us-east-2.amazonaws.com:8080/about

# Test application endpoint with Host header (for ingress)
curl -i --header "Host: ex6.antonputra.com" http://k8s-6example-myapp-c79dafe9b7-67845894.us-east-2.elb.amazonaws.com/about
```

## Project Structure

```
.
├── Makefile                  # Deployment automation
├── terraform.tfvars          # Unified configuration file (all variables)
├── state.config              # Backend configuration (region and bucket)
├── envs/
│   ├── global/
│   │   └── s3/               # S3 backend module
│   │       ├── providers.tf
│   │       ├── variables.tf
│   │       ├── s3.tf
│   │       ├── state.tf
│   │       └── outputs.tf
│   └── staging/
│       ├── vpc/              # VPC module
│       │   ├── providers.tf
│       │   ├── variables.tf
│       │   ├── main.tf
│       │   ├── state.tf
│       │   └── outputs.tf
│       ├── eks/              # EKS module (cluster only)
│       │   ├── providers.tf
│       │   ├── variables.tf
│       │   ├── data.tf
│       │   ├── eks.tf
│       │   ├── nodes.tf
│       │   ├── iam-users.tf
│       │   ├── iam-roles.tf
│       │   ├── pod-identity.tf
│       │   ├── iam-oidc.tf
│       │   ├── state.tf
│       │   └── outputs.tf
│       └── workloads/        # Workloads and applications
│           ├── metrics-server/
│           │   ├── providers.tf
│           │   ├── variables.tf
│           │   ├── data.tf
│           │   ├── metrics-server.tf
│           │   ├── state.tf
│           │   ├── outputs.tf
│           │   └── values/
│           │       └── metrics-server.yaml
│           ├── cluster-autoscaler/
│           │   ├── providers.tf
│           │   ├── variables.tf
│           │   ├── data.tf
│           │   ├── cluster-autoscaler.tf
│           │   ├── state.tf
│           │   └── outputs.tf
│           ├── aws-lbc/
│           │   ├── providers.tf
│           │   ├── variables.tf
│           │   ├── data.tf
│           │   ├── aws-lbc.tf
│           │   ├── state.tf
│           │   ├── outputs.tf
│           │   └── iam/
│           │       └── AWSLoadBalancerController.json
│           ├── nginx-ingress/
│           │   ├── providers.tf
│           │   ├── variables.tf
│           │   ├── data.tf
│           │   ├── nginx-ingress.tf
│           │   ├── state.tf
│           │   ├── outputs.tf
│           │   └── values/
│           │       └── nginx-ingress.yaml
│           ├── cert-manager/
│           │   ├── providers.tf
│           │   ├── variables.tf
│           │   ├── data.tf
│           │   ├── cert-manager.tf
│           │   ├── state.tf
│           │   └── outputs.tf
│           ├── ebs-csi-driver/
│           │   ├── providers.tf
│           │   ├── variables.tf
│           │   ├── data.tf
│           │   ├── ebs-csi-driver.tf
│           │   ├── state.tf
│           │   └── outputs.tf
│           ├── efs-csi-driver/
│           │   ├── providers.tf
│           │   ├── variables.tf
│           │   ├── data.tf
│           │   ├── efs-csi-driver.tf
│           │   ├── state.tf
│           │   └── outputs.tf
│           ├── argocd/
│           │   ├── providers.tf
│           │   ├── variables.tf
│           │   ├── data.tf
│           │   ├── argocd.tf
│           │   ├── state.tf
│           │   ├── outputs.tf
│           │   └── values/
│           │       └── argocd-values.yml
│           ├── argocd-ingress/
│           │   ├── providers.tf
│           │   ├── variables.tf
│           │   ├── data.tf
│           │   ├── argocd-ingress.tf
│           │   ├── state.tf
│           │   └── outputs.tf
│           └── vprofile-app/
│               ├── providers.tf
│               ├── variables.tf
│               ├── data.tf
│               ├── vprofile-app.tf
│               ├── state.tf
│               └── outputs.tf
```

## Destroying Infrastructure

⚠️ **Warning**: Destroy resources in reverse order to avoid dependency issues.

### Using Makefile (Recommended)

```bash
# Destroy all workloads
make destroy-workloads

# Destroy infrastructure (VPC + EKS)
make destroy-infrastructure

# Destroy everything
make destroy-all
```

### Manual Destruction

If you prefer to destroy manually:

```bash
# Destroy workloads in reverse order
cd envs/staging/workloads/vprofile-app && terraform destroy -var-file=../../../../terraform.tfvars -auto-approve
cd ../argocd-ingress && terraform destroy -var-file=../../../../terraform.tfvars -auto-approve
# ... continue for all workloads

# Destroy EKS cluster
cd ../../eks && terraform destroy -var-file=../../../terraform.tfvars -auto-approve

# Destroy VPC
cd ../vpc && terraform destroy -var-file=../../../terraform.tfvars -auto-approve

# Destroy S3 backend (only if you want to remove state storage)
cd ../../global/s3 && terraform destroy -var-file=../../../terraform.tfvars -auto-approve
```

## Notes

- The EKS cluster uses private subnets for worker nodes
- Public endpoint access is enabled for the EKS API server
- Bootstrap cluster creator admin permissions are enabled
- All resources are tagged with the environment name
- Terraform state is stored in S3 with versioning enabled
- Each workload module has its own Terraform state file
- All Helm releases use atomic installs (delete on fail)
- Each workload creates and manages its own namespace
- Kubernetes resources are isolated in their respective namespaces
- The cluster autoscaler will automatically scale nodes based on workload
- ArgoCD is configured with TLS certificates via cert-manager
- EFS storage class is available for persistent volumes
- Workloads can be deployed independently and in parallel where dependencies allow

## Troubleshooting

### S3 Bucket Already Exists

If you encounter an error that the S3 bucket already exists, you have three options:

**Option A: Import the existing bucket** (recommended if you want to use it)
```bash
cd envs/global/s3
terraform import aws_s3_bucket.terraform_state vprofile-move35623-add-terraform-state
terraform import aws_s3_bucket_versioning.terraform_state vprofile-move35623-add-terraform-state
terraform import aws_s3_bucket_server_side_encryption_configuration.terraform_state vprofile-move35623-add-terraform-state
terraform import aws_s3_bucket_public_access_block.terraform_state vprofile-move35623-add-terraform-state
```

**Option B: Use a different bucket name**
Edit `terraform.tfvars` at the root level and change the `bucket` variable to something unique.

**Option C: Delete the existing bucket** (only if it's empty and you don't need it)
```bash
aws s3 rb s3://vprofile-move35623-add-terraform-state --force
```

### Variable Warnings

If you see warnings about undeclared variables, ensure you're using the root `terraform.tfvars` file. Each module only accepts variables declared in its `variables.tf` file.

### Cannot connect to cluster
```bash
# Verify AWS credentials
aws sts get-caller-identity

# Update kubeconfig
aws eks update-kubeconfig --name staging-demo3 --region us-west-2
```

### Pods stuck in Pending
```bash
# Check node capacity
kubectl get nodes
kubectl describe nodes

# Check cluster autoscaler logs
kubectl logs -n kube-system -l app=cluster-autoscaler
```

### ArgoCD not accessible
```bash
# Check ingress controller
kubectl get pods -n ingress-nginx

# Check ArgoCD service
kubectl get svc -n argocd

# Check certificate status
kubectl describe certificate -n argocd

# Check ArgoCD pods
kubectl get pods -n argocd
```

### Workload Installation Order

If a workload fails to install, ensure dependencies are met:

1. **Prerequisites**: S3 backend → VPC → EKS cluster
2. **Foundation**: metrics-server → cluster-autoscaler → aws-lbc → nginx-ingress → cert-manager
3. **Storage**: ebs-csi-driver and efs-csi-driver (can run in parallel)
4. **GitOps**: argocd (depends on cert-manager and nginx-ingress)
5. **Applications**: argocd-ingress → vprofile-app

Each workload module is independent and can be destroyed/recreated without affecting others (except for dependencies).

## References

- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
