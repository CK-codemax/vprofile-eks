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
- AWS CLI configured with appropriate credentials
- AWS account with permissions to create EKS clusters, VPCs, and related resources
- kubectl installed and configured
- Helm 3.x installed (for ArgoCD helm chart)

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

## Commands

### Step 1: Initialize and Create S3 Backend

The S3 backend must be created first, as it's used to store Terraform state for all other modules.

```bash
# Navigate to S3 backend directory
cd envs/global/s3

# Initialize Terraform (without backend first time)
terraform init

# Apply to create S3 bucket
terraform apply -var-file=../../../terraform.tfvars

# Reinitialize with backend configuration
terraform init -migrate-state -backend-config=../../../state.config
```

### Step 2: Deploy VPC Infrastructure

```bash
# Navigate to VPC directory
cd ../../staging/vpc

# Initialize Terraform with backend
terraform init -backend-config=../../../state.config

# Review planned changes
terraform plan -var-file=../../../terraform.tfvars

# Apply VPC configuration
terraform apply -var-file=../../../terraform.tfvars
```

### Step 3: Deploy EKS Cluster

```bash
# Navigate to EKS directory
cd ../eks

# Initialize Terraform with backend
terraform init -backend-config=../../../state.config

# Review planned changes
terraform plan -var-file=../../../terraform.tfvars

# Apply EKS configuration (this will take 10-15 minutes)
terraform apply -var-file=../../../terraform.tfvars
```

### Step 4: Configure kubectl

```bash
# Update kubeconfig to connect to your cluster
aws eks update-kubeconfig --name staging-demo3 --region us-west-2

# Verify cluster access
kubectl get nodes

# Wait for nodes to be ready
kubectl wait --for=condition=Ready nodes --all --timeout=300s
```

### Step 5: Deploy Infrastructure Workloads

Workloads must be deployed in the correct order due to dependencies. Each workload creates its own namespace and uses atomic Helm installs (delete on fail).

#### 5.1: Metrics Server (No dependencies)

```bash
cd ../workloads/metrics-server
terraform init -backend-config=../../../../state.config
terraform apply -var-file=../../../../terraform.tfvars

# Verify installation
kubectl get pods -n metrics-server
```

#### 5.2: Cluster Autoscaler (Depends on: metrics-server)

```bash
cd ../cluster-autoscaler
terraform init -backend-config=../../../../state.config
terraform apply -var-file=../../../../terraform.tfvars

# Verify installation
kubectl get pods -n cluster-autoscaler
```

#### 5.3: AWS Load Balancer Controller (Depends on: cluster-autoscaler)

```bash
cd ../aws-lbc
terraform init -backend-config=../../../../state.config
terraform apply -var-file=../../../../terraform.tfvars

# Verify installation
kubectl get pods -n aws-load-balancer-controller
```

#### 5.4: Nginx Ingress Controller (Depends on: aws-lbc)

```bash
cd ../nginx-ingress
terraform init -backend-config=../../../../state.config
terraform apply -var-file=../../../../terraform.tfvars

# Verify installation (wait for LoadBalancer to be provisioned)
kubectl get svc -n ingress-nginx
kubectl get pods -n ingress-nginx
```

#### 5.5: Cert Manager (Depends on: nginx-ingress)

```bash
cd ../cert-manager
terraform init -backend-config=../../../../state.config
terraform apply -var-file=../../../../terraform.tfvars

# Verify installation
kubectl get pods -n cert-manager
```

#### 5.6: EBS CSI Driver (No Helm dependencies, can run in parallel)

```bash
cd ../ebs-csi-driver
terraform init -backend-config=../../../../state.config
terraform apply -var-file=../../../../terraform.tfvars

# Verify installation
kubectl get pods -n ebs-csi-driver
```

#### 5.7: EFS CSI Driver (No Helm dependencies, can run in parallel)

```bash
cd ../efs-csi-driver
terraform init -backend-config=../../../../state.config
terraform apply -var-file=../../../../terraform.tfvars

# Verify installation
kubectl get pods -n efs-csi-driver
kubectl get storageclass efs
```

#### 5.8: ArgoCD (Depends on: cert-manager, nginx-ingress)

```bash
cd ../argocd
terraform init -backend-config=../../../../state.config
terraform apply -var-file=../../../../terraform.tfvars

# Wait for ArgoCD to be ready (this may take a few minutes)
kubectl wait --for=condition=Ready pods -l app.kubernetes.io/name=argocd-server -n argocd --timeout=600s
kubectl get pods -n argocd
```

### Step 6: Deploy Application Workloads

#### 6.1: ArgoCD Ingress (Depends on: argocd, cert-manager, nginx-ingress)

```bash
cd ../argocd-ingress
terraform init -backend-config=../../../../state.config
terraform apply -var-file=../../../../terraform.tfvars

# Verify ingress and certificate
kubectl get ingress -n argocd
kubectl get certificate -n argocd
```

#### 6.2: VProfile Application (Depends on: argocd)

```bash
cd ../vprofile-app
terraform init -backend-config=../../../../state.config
terraform apply -var-file=../../../../terraform.tfvars

# Verify ArgoCD application
kubectl get application -n argocd
```

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

```bash
# Destroy application workloads first
cd envs/staging/workloads/vprofile-app
terraform init -backend-config=../../../../state.config
terraform destroy -var-file=../../../../terraform.tfvars

cd ../argocd-ingress
terraform init -backend-config=../../../../state.config
terraform destroy -var-file=../../../../terraform.tfvars

# Destroy infrastructure workloads (in reverse order)
cd ../argocd
terraform init -backend-config=../../../../state.config
terraform destroy -var-file=../../../../terraform.tfvars

cd ../efs-csi-driver
terraform init -backend-config=../../../../state.config
terraform destroy -var-file=../../../../terraform.tfvars

cd ../ebs-csi-driver
terraform init -backend-config=../../../../state.config
terraform destroy -var-file=../../../../terraform.tfvars

cd ../cert-manager
terraform init -backend-config=../../../../state.config
terraform destroy -var-file=../../../../terraform.tfvars

cd ../nginx-ingress
terraform init -backend-config=../../../../state.config
terraform destroy -var-file=../../../../terraform.tfvars

cd ../aws-lbc
terraform init -backend-config=../../../../state.config
terraform destroy -var-file=../../../../terraform.tfvars

cd ../cluster-autoscaler
terraform init -backend-config=../../../../state.config
terraform destroy -var-file=../../../../terraform.tfvars

cd ../metrics-server
terraform init -backend-config=../../../../state.config
terraform destroy -var-file=../../../../terraform.tfvars

# Destroy EKS cluster
cd ../../eks
terraform destroy -var-file=../../../terraform.tfvars

# Destroy VPC
cd ../vpc
terraform destroy -var-file=../../../terraform.tfvars

# Destroy S3 backend (only if you want to remove state storage)
cd ../../global/s3
terraform destroy -var-file=../../../terraform.tfvars
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
