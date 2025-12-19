# VProfile EKS Infrastructure

![Kubernetes](https://img.shields.io/badge/kubernetes-v1.28-326CE5?style=flat&logo=kubernetes&logoColor=white)
![Ansible](https://img.shields.io/badge/ansible-automated-EE0000?style=flat&logo=ansible&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-232F3E?style=flat&logo=amazon-aws&logoColor=white)
![EKS](https://img.shields.io/badge/EKS-managed-FF9900?style=flat&logo=amazon-eks&logoColor=white)
![EC2](https://img.shields.io/badge/EC2-instances-FF9900?style=flat&logo=amazon-ec2&logoColor=white)
![S3](https://img.shields.io/badge/S3-storage-569A31?style=flat&logo=amazon-s3&logoColor=white)
![Terraform](https://img.shields.io/badge/terraform-infrastructure-7B42BC?style=flat&logo=terraform&logoColor=white)
![ArgoCD](https://img.shields.io/badge/argocd-gitops-EF7B4D?style=flat&logo=argo&logoColor=white)

Production-ready AWS EKS cluster with GitOps deployment using Terraform. Automates deployment of the VProfile application with enterprise-grade security, scalability, and automation.

## Key Features

- **Production-Ready**: Fully configured EKS cluster with high availability
- **GitOps**: Automated CI/CD using ArgoCD
- **Auto-Scaling**: Dynamic pod and node scaling
- **TLS Automation**: Automatic certificate provisioning via Let's Encrypt
- **IAM Integration**: Fine-grained access control with AWS IAM and Kubernetes RBAC
- **Multi-Storage**: EBS and EFS persistent storage options

## Architecture Components

1. **S3 Backend** - Terraform state storage with versioning and encryption
2. **VPC** - Network with public/private subnets across 2 AZs
3. **EKS Cluster** - Managed Kubernetes control plane (v1.29)
4. **IAM Roles/Users** - Admin and developer access with RBAC
5. **Pod Identity** - Service account-based IAM for pods
6. **Metrics Server** - Resource metrics for autoscaling
7. **Cluster Autoscaler** - Automatic node scaling
8. **AWS Load Balancer Controller** - ALB/NLB integration
9. **Nginx Ingress** - HTTP/HTTPS routing and SSL termination
10. **Cert-Manager** - Automatic TLS certificate management
11. **ClusterIssuer** - Let's Encrypt configuration
12. **EBS CSI Driver** - Block storage for databases
13. **EFS CSI Driver** - Shared file storage
14. **ArgoCD** - GitOps continuous deployment
15. **ArgoCD Ingress** - External HTTPS access
16. **VProfile App** - Application deployment via ArgoCD

## How It Works

### Infrastructure Deployment Flow

The deployment follows a layered approach, where each layer depends on the previous one:

1. **S3 Backend** (`envs/global/s3/`)
   - Creates an S3 bucket for storing Terraform state files
   - Enables versioning and encryption for state file safety
   - Provides a centralized location for state management across team members
   - State files are stored with the pattern: `staging/<module>/terraform.tfstate`

2. **VPC Module** (`envs/staging/vpc/`)
   - Provisions a Virtual Private Cloud with public and private subnets across 2 availability zones
   - Creates Internet Gateway for public subnet internet access
   - Sets up NAT Gateways for private subnet outbound internet access
   - Outputs subnet IDs that are consumed by the EKS module via `terraform_remote_state`

3. **EKS Module** (`envs/staging/eks/`)
   - Creates IAM roles for the EKS cluster and node groups
   - Provisions the EKS control plane (managed by AWS)
   - Creates managed node groups in private subnets for security
   - Sets up IAM users (manager, developer) with Kubernetes RBAC bindings
   - Configures Pod Identity associations for service accounts to assume IAM roles
   - Outputs cluster information (endpoint, CA certificate) used by workload modules

### Workload Deployment Flow

Workloads are deployed as separate Terraform modules, each with its own state file. They follow a specific order due to dependencies:

1. **Metrics Server** (`workloads/metrics-server/`)
   - Deploys Kubernetes Metrics Server via Helm
   - Collects resource usage metrics (CPU, memory) from nodes and pods
   - Required by HPA (Horizontal Pod Autoscaler) and Cluster Autoscaler
   - Uses `kubernetes` provider to authenticate with EKS cluster

2. **Cluster Autoscaler** (`workloads/cluster-autoscaler/`)
   - Deploys AWS Cluster Autoscaler via Helm
   - Monitors pods that cannot be scheduled due to insufficient resources
   - Automatically adds/removes nodes in the EKS node group
   - Requires Pod Identity to assume an IAM role with permissions to modify autoscaling groups
   - Reads cluster state from remote state (EKS module)

3. **AWS Load Balancer Controller** (`workloads/aws-lbc/`)
   - Creates IAM role and policy for managing AWS Load Balancers
   - Sets up Pod Identity association for the controller's service account
   - Deploys AWS Load Balancer Controller via Helm
   - Watches for Kubernetes Ingress and Service resources with annotations
   - Automatically provisions AWS Application/Network Load Balancers

4. **Nginx Ingress Controller** (`workloads/nginx-ingress/`)
   - Deploys Nginx Ingress Controller via Helm
   - Creates a LoadBalancer service that triggers AWS LBC to provision an NLB
   - Configures ingress class `external-nginx` for routing HTTP/HTTPS traffic
   - Acts as the entry point for external traffic into the cluster

5. **Cert-Manager** (`workloads/cert-manager/`)
   - Deploys Cert-Manager via Helm with CRDs enabled
   - Installs Custom Resource Definitions (CRDs) for Certificate and ClusterIssuer resources
   - Provides API endpoints for TLS certificate management
   - Does not provision certificates yet (requires ClusterIssuer)

6. **ClusterIssuer** (`workloads/cluster-issuer/`)
   - Creates a ClusterIssuer resource using `kubernetes_manifest`
   - Configures Let's Encrypt production ACME server
   - Sets up HTTP-01 challenge solver using `external-nginx` ingress class
   - Depends on cert-manager CRDs being available
   - Allows any namespace to request certificates using this issuer

7. **EBS CSI Driver** (`workloads/ebs-csi-driver/`)
   - Creates IAM role for EBS volume operations
   - Sets up Pod Identity association
   - Deploys EBS CSI driver via Helm
   - Enables pods to use AWS Elastic Block Store volumes (e.g., for databases)

8. **EFS CSI Driver** (`workloads/efs-csi-driver/`)
   - Creates EFS file system and mount targets in VPC subnets
   - Creates IAM role for EFS operations
   - Sets up Pod Identity association
   - Deploys EFS CSI driver via Helm
   - Enables pods to use AWS Elastic File System for shared storage

9. **ArgoCD** (`workloads/argocd/`)
   - Creates `argocd` namespace
   - Deploys ArgoCD via Helm chart
   - Installs ArgoCD server, repo server, application controller, and other components
   - Provides GitOps continuous deployment capabilities

10. **ArgoCD Ingress** (`workloads/argocd-ingress/`)
    - Creates Kubernetes Ingress resource using `kubernetes_manifest`
    - Configures routing for `argo.ochukowhoro.xyz` domain
    - Uses `cert-manager.io/cluster-issuer` annotation to trigger certificate provisioning
    - AWS Load Balancer Controller creates an ALB based on this ingress
    - Cert-Manager automatically provisions TLS certificate via Let's Encrypt

11. **VProfile App** (`workloads/vprofile-app/`)
    - Creates an ArgoCD AppProject using `kubernetes_manifest`
    - Defines project permissions (source repos, destinations, cluster resources)
    - Creates an ArgoCD Application resource pointing to the Git repository
    - Configures automated sync with self-healing and pruning enabled
    - ArgoCD continuously monitors the Git repo and syncs changes to the cluster

### Component Interactions

```
┌─────────────────────────────────────────────────────────────┐
│                     Terraform Deployment                    │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│  S3 Backend ──► VPC ──► EKS ──► Workloads (sequential)      │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                    Kubernetes Cluster                       │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │ Metrics      │  │ Cluster      │  │ AWS LBC      │     │
│  │ Server       │──│ Autoscaler   │  │ Controller   │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
│                                              │              │
│  ┌──────────────┐  ┌──────────────┐         │              │
│  │ Nginx        │  │ Cert-        │         │              │
│  │ Ingress      │──│ Manager      │         │              │
│  └──────────────┘  └──────────────┘         │              │
│         │                  │                 │              │
│         │                  ▼                 │              │
│         │         ┌──────────────┐          │              │
│         │         │ ClusterIssuer│          │              │
│         │         └──────────────┘          │              │
│         │                                   │              │
│         ▼                                   ▼              │
│  ┌──────────────┐                   ┌──────────────┐     │
│  │ ArgoCD       │                   │ AWS ALB/NLB  │     │
│  │ Ingress      │───────────────────│ (Provisioned)│     │
│  └──────────────┘                   └──────────────┘     │
│         │                                                 │
│         ▼                                                 │
│  ┌──────────────┐                                         │
│  │ ArgoCD       │                                         │
│  │ Application  │                                         │
│  └──────────────┘                                         │
│         │                                                 │
│         ▼                                                 │
│  ┌──────────────┐                                         │
│  │ VProfile App │                                         │
│  │ (from Git)   │                                         │
│  └──────────────┘                                         │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                      GitOps Flow                            │
│  Git Repo ──► ArgoCD ──► Kubernetes Resources               │
└─────────────────────────────────────────────────────────────┘
```

### How Terraform Manages State

- **Remote State**: Each module uses S3 backend for state storage
- **State Dependencies**: Modules read each other's outputs via `data.terraform_remote_state`
- **Example**: EKS module reads VPC subnet IDs, workloads read EKS cluster endpoint
- **State Isolation**: Each workload has its own state file (`staging/workloads/<name>/terraform.tfstate`)
- **State Locking**: DynamoDB table (configured in `state.config`) prevents concurrent modifications

### How GitOps Works

1. **ArgoCD Application** (`vprofile-app` module):
   - Monitors Git repository (`var.argocd_app_repo_url`)
   - Watches specific path (`var.argocd_app_source_path`) and branch/tag (`var.argocd_app_repo_target_revision`)
   - Compares Git state with cluster state
   - Automatically syncs when differences are detected (if `automated.sync` is enabled)

2. **Automated Sync Policy**:
   - `prune: true` - Removes resources deleted from Git
   - `selfHeal: true` - Reverts manual changes back to Git state
   - `CreateNamespace=true` - Automatically creates namespaces if missing

3. **Certificate Provisioning Flow**:
   - Ingress resource created with `cert-manager.io/cluster-issuer` annotation
   - Cert-Manager detects the annotation and creates a Certificate resource
   - Certificate controller requests certificate from Let's Encrypt via ClusterIssuer
   - Let's Encrypt performs HTTP-01 challenge through Nginx Ingress
   - Once validated, certificate is stored as Kubernetes Secret
   - Ingress uses the secret for TLS termination

### Security Features

- **Network Isolation**: EKS nodes run in private subnets, only control plane exposed
- **IAM Integration**: Kubernetes RBAC maps to AWS IAM users/roles
- **Pod Identity**: Service accounts assume IAM roles without static credentials
- **TLS Encryption**: All external traffic encrypted via Let's Encrypt certificates
- **Least Privilege**: IAM policies grant minimal required permissions

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) >= 1.0
- [AWS CLI](https://aws.amazon.com/cli/) installed and configured
- [kubectl](https://kubernetes.io/docs/tasks/tools/) installed
- [Helm](https://helm.sh/docs/intro/install/) 3.x installed

## Quick Start (Local Deployment)

```bash
# 1. Deploy S3 backend (state bucket) - run from your terminal only
make deploy-s3

# 2. (Optional, once backend config is uncommented) Migrate existing local state to S3
make migrate-s3-backend

# 3. Deploy infrastructure (VPC + EKS)
make deploy-infrastructure

# 4. Update kubectl config
make update-kubeconfig
make verify-cluster

# 5. Deploy all workloads
make deploy-workloads

# Or deploy everything:
make deploy-all
```

**Important**:
- **Backend S3 bucket and state migration must always be created/managed from your terminal**, not from GitHub Actions.
- GitHub Actions workflows only operate on the **VPC**, **EKS**, and **workloads** Terraform modules and reuse the existing remote state.

## CI/CD with GitHub Actions (Self-Hosted Runner)

This project also supports automated deployment using **GitHub Actions** and a **self-hosted Ubuntu runner**. The Actions workflows call dedicated CI Make targets that rely on `TF_VAR_*` environment variables instead of `terraform.tfvars`.

### Overview

- **Local deployment**:
  - Uses `terraform.tfvars` for configuration.
  - Uses standard Make targets: `make deploy-vpc`, `make deploy-eks`, `make deploy-workloads`, etc.
- **GitHub Actions deployment**:
  - Uses `TF_VAR_*` environment variables / secrets (one per variable in `terraform.tfvars`).
  - Uses CI-specific Make targets:
    - `make deploy-vpc-ci`
    - `make deploy-eks-ci`
    - `make deploy-workloads-ci`
  - Runs only after a **PR is approved and merged to `main`** (push to `main`).

### Required GitHub Actions Secrets

#### Backend Configuration Secrets

These secrets are required for Terraform backend initialization (S3 state storage) and must be configured in all GitHub Actions workflows:

- `TF_BACKEND_BUCKET` - The S3 bucket name for storing Terraform state (e.g., `vprofile-ochuko`)
- `TF_BACKEND_REGION` - The AWS region where the S3 bucket is located (e.g., `us-east-2`)

These values should match what you have in your `state.config` file for local deployments.

**Important**: These backend configuration secrets are used by all three workflows (VPC, EKS, and Workloads) to initialize Terraform with the S3 backend.

#### Required TF_VAR Secrets

For GitHub Actions, create repository or organization secrets for each Terraform variable, prefixed with `TF_VAR_`. Example mapping from `terraform.tfvars`:

- **Environment & Regions**
  - `TF_VAR_env`
  - `TF_VAR_region`
  - `TF_VAR_terraform_s3_bucket`
  - `TF_VAR_eks_cluster_name`
  - `TF_VAR_aws_region`

Make sure the values of these secrets match what you would normally put in `terraform.tfvars` for local runs.

**Note**: VPC networking configuration (CIDR blocks, availability zones), EKS cluster version, node group configuration (instance types, scaling), ArgoCD configuration (domain, cert issuer, app settings), Cert-Manager email, IAM policy names, user names, and EFS creation tokens are now hardcoded in the Terraform modules and do not need to be provided as secrets.

**To customize these values**, edit the following Terraform files directly:
- **VPC/Networking**: `envs/staging/vpc/main.tf`
- **EKS Configuration**: `envs/staging/eks/eks.tf` and `envs/staging/eks/nodes.tf`
- **ArgoCD Ingress**: `envs/staging/workloads/argocd-ingress/argocd-ingress.tf`
- **Cert-Manager**: `envs/staging/workloads/cluster-issuer/cluster-issuer.tf`
- **ArgoCD Application**: `envs/staging/workloads/vprofile-app/vprofile-app.tf`

### Self-Hosted Runner Requirements

- A **self-hosted Ubuntu runner** registered with your GitHub repository/organization.
- The runner must have:
  - `make` installed (required for running deployment commands).
  - `terraform` installed (version compatible with this project).
  - `aws` CLI installed and configured.
  - `docker` installed with the ubuntu user added to the docker group (to run docker without sudo).
  - `kubectl` and `helm` if you want to run verification commands from Actions (optional).

The workflows use `runs-on: self-hosted` so they will execute on your own runner instead of GitHub-hosted runners.

#### EC2 Instance Role Configuration

**Important**: The self-hosted runner should be deployed on an **EC2 instance with an IAM instance role** attached. This is the recommended and secure way to provide AWS credentials to the runner.

**Required IAM Permissions**

The EC2 instance role must have **AdministratorAccess** to manage all AWS resources required for this infrastructure.

**Setting Up the Self-Hosted Runner**

Please refer to the official documentation for detailed setup instructions:

- **IAM Roles for EC2**: [AWS Documentation - Using IAM Roles for EC2](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/iam-roles-for-amazon-ec2.html)
- **EC2 Instance Launch**: [AWS Documentation - Launching an Instance](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/LaunchingAndUsingInstances.html)
- **Terraform Installation**: [Terraform Installation Guide](https://developer.hashicorp.com/terraform/downloads)
- **AWS CLI Installation**: [AWS CLI Installation Guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- **Docker Installation**: [Docker Engine Installation Guide](https://docs.docker.com/engine/install/ubuntu/)
- **GitHub Actions Self-Hosted Runners**: [GitHub Documentation - Self-Hosted Runners](https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/about-self-hosted-runners)

**Required Setup**:
- Create an EC2 instance (Ubuntu 22.04 LTS or later) with an IAM role attached that has AdministratorAccess
- Install Terraform, AWS CLI, and Docker on the instance
- Ensure the ubuntu user can run Docker without sudo (add to docker group)
- Register the GitHub Actions runner following the official GitHub documentation

### GitHub Actions Workflows

Three workflows are provided under `.github/workflows/` and are designed to reflect the dependency order of the Terraform modules:

- **VPC Workflow** (`vpc.yml`)
  - Trigger: `push` to `main` when VPC or shared config files change.
  - Runner: `self-hosted`.
  - Command: `make deploy-vpc-ci`.

- **EKS Workflow** (`eks.yml`)
  - Trigger: `push` to `main` when EKS or shared config files change.
  - Runner: `self-hosted`.
  - Command: `make deploy-eks-ci`.
  - **Depends on** VPC state existing in the remote backend.

- **Workloads Workflow** (`workloads.yml`)
  - Trigger: `push` to `main` when workloads or shared config files change.
  - Runner: `self-hosted`.
  - Command: `make deploy-workloads-ci`.
  - **Depends on** EKS state existing in the remote backend.

Although GitHub Actions workflows cannot have hard cross-workflow dependencies, the Terraform modules themselves depend on each other via remote state:

- VPC must exist before EKS can be deployed.
- EKS must exist before workloads can be deployed.

When making changes that span multiple layers (e.g., VPC and EKS), create a PR that includes all relevant Terraform changes, get it **approved by an administrator**, and let the workflows run in the expected order after merge. You can always manually re-run a workflow from the GitHub UI if needed.

### Branch Protection and PR Flow

To ensure that infrastructure changes are always reviewed:

- **Protect the `main` branch** in your GitHub repository:
  - Disallow direct pushes to `main`.
  - Require pull request reviews (ideally from an administrator) before merging.
- Configure your PR workflow so that:
  - Developers open PRs from feature branches.
  - An administrator reviews and approves.
  - Once merged into `main`, the appropriate GitHub Actions workflows run automatically and apply the Terraform changes using the CI Make targets.

## How the Makefile Works

The `Makefile` orchestrates the entire deployment process, handling Terraform initialization, planning, and applying for each module:

### Key Features

- **Non-Interactive**: All Terraform commands use `-input=false` and `-auto-approve` flags
- **Sequential Deployment**: Workloads deploy one at a time using a `deploy-workload` macro
- **State Management**: Each module initializes with backend config pointing to S3
- **Path Handling**: Correctly resolves relative paths from each module directory to root config files
- **Error Prevention**: `-compact-warnings` flag suppresses verbose warnings

### Deployment Process

1. **`make deploy-s3`**:
   - Runs `terraform init`, `plan`, and `apply` in `envs/global/s3/`
   - Uses `terraform.tfvars` from root (`../../../terraform.tfvars`)
   - Creates S3 bucket for state storage
   - Prints instructions to uncomment backend config before migration

2. **`make migrate-s3-backend`**:
   - Pipes "yes" to `terraform init -migrate-state` to copy local state to S3
   - Non-interactive state migration

3. **`make deploy-vpc`**:
   - Initializes Terraform with S3 backend config
   - Plans and applies VPC resources
   - Reads variables from root `terraform.tfvars`
   - Stores state in S3 at `staging/vpc/terraform.tfstate`

4. **`make deploy-eks`**:
   - Similar to VPC, but for EKS cluster
   - Reads VPC subnet IDs from remote state
   - Stores state in S3 at `staging/eks/terraform.tfstate`

5. **`make deploy-workloads`**:
   - Uses `$(call deploy-workload,<name>)` macro for each workload
   - Macro executes: `cd workloads/<name>`, `terraform init`, `plan`, `apply`
   - Each workload module reads:
     - Backend config: `../../../../state.config`
     - Variables: `../../../../terraform.tfvars`
   - Workloads deploy sequentially to respect dependencies

### Why Sequential Deployment?

Terraform modules cannot directly depend on each other's resources when using separate state files. Sequential deployment ensures:
- Resources are created in the correct order
- Remote state data sources can find their dependencies
- Each module completes before the next starts

### State File Structure

```
S3 Bucket: <bucket-name>
├── staging/
│   ├── vpc/terraform.tfstate
│   ├── eks/terraform.tfstate
│   └── workloads/
│       ├── metrics-server/terraform.tfstate
│       ├── cluster-autoscaler/terraform.tfstate
│       ├── aws-lbc/terraform.tfstate
│       └── ... (one state file per workload)
```

## Configuration

Edit `terraform.tfvars` at the root to configure all variables. All modules use this unified configuration file.

**Default values:**
- Environment: staging
- Region: us-west-2
- EKS Cluster: staging-demo3
- EKS Version: 1.29

## Available Commands

### Infrastructure
- `make deploy-s3` - Deploy S3 backend
- `make deploy-vpc` - Deploy VPC
- `make deploy-eks` - Deploy EKS cluster
- `make deploy-infrastructure` - Deploy VPC + EKS

### Workloads
- `make deploy-workloads` - Deploy all workloads
- `make deploy-all` - Deploy infrastructure + workloads

**Individual workload targets:**
- `make deploy-metrics-server`
- `make deploy-cluster-autoscaler`
- `make deploy-aws-lbc`
- `make deploy-nginx-ingress`
- `make deploy-cert-manager`
- `make deploy-cluster-issuer`
- `make deploy-ebs-csi-driver`
- `make deploy-efs-csi-driver`
- `make deploy-argocd`
- `make deploy-argocd-ingress`
- `make deploy-vprofile-app`

### Planning & Destruction
- `make plan-vpc` - Plan VPC changes
- `make plan-eks` - Plan EKS changes
- `make destroy-workloads` - Destroy all workloads
- `make destroy-infrastructure` - Destroy VPC and EKS
- `make destroy-all` - Destroy everything

### Utilities
- `make update-kubeconfig` - Update kubectl config
- `make verify-cluster` - Verify cluster access
- `make clean` - Clean Terraform files

## Workload Deployment Order

Workloads must be deployed in this order:

1. metrics-server
2. cluster-autoscaler
3. aws-lbc
4. nginx-ingress
5. cert-manager
6. cluster-issuer
7. ebs-csi-driver
8. efs-csi-driver
9. argocd
10. argocd-ingress
11. vprofile-app

## Access ArgoCD

After deployment, access ArgoCD at: `https://argo.ochukowhoro.xyz`

```bash
# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo

## DNS Configuration

After deploying ingress resources, update your DNS records to point to the load balancer endpoints for secure HTTPS access.

### Get Load Balancer Endpoints

```bash
# Get ArgoCD ingress load balancer address
kubectl get ingress -n argocd argocd-server-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# Get Nginx Ingress Controller load balancer (for all ingresses)
kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# Get all ingress resources and their load balancer addresses
kubectl get ingress --all-namespaces -o wide
```

### Update DNS Records

1. **For ArgoCD**: Point your domain (e.g., `argo.ochukowhoro.xyz`) to the ArgoCD ingress load balancer address
2. **For Applications**: Point your application domains(e.g., `vprofile.ochukowhoro.xyz`) to the Nginx Ingress Controller load balancer address

**Important**: 
- Use **CNAME** records pointing to the load balancer hostname
- DNS propagation may take a few minutes
- Cert-manager will automatically provision TLS certificates once DNS is configured correctly

**Example DNS Configuration:**
```
Type: CNAME
Name: argo
Value: k8s-argocd-xxxxx-xxxxx.us-west-2.elb.amazonaws.com
TTL: 300
```

### Verify DNS and Certificate

```bash
# Check ingress status
kubectl get ingress -n argocd

# Check certificate status (should show Ready after DNS propagation)
kubectl get certificate -n argocd

# Describe certificate for detailed status
kubectl describe certificate -n argocd
```

## Architecture Advantages

- **Scalability**: Auto-scaling pods and nodes
- **Security**: Private subnets, IAM integration, TLS encryption
- **Automation**: GitOps, Infrastructure as Code, automatic certificates
- **Cost Optimization**: Cluster autoscaler, efficient resource usage
- **High Availability**: Multi-AZ deployment, managed control plane
- **Developer Experience**: Simple deployment, GitOps workflow

## Troubleshooting

### S3 Bucket Already Exists
Change bucket name in `terraform.tfvars` or import existing bucket.

### Cannot Connect to Cluster
```bash
aws sts get-caller-identity
make update-kubeconfig
```

### Pods Stuck in Pending
```bash
kubectl get nodes
kubectl describe nodes
kubectl logs -n kube-system -l app=cluster-autoscaler
```

### ArgoCD Not Accessible
```bash
kubectl get pods -n argocd
kubectl get ingress -n argocd
kubectl get certificate -n argocd
```

## Project Structure

```
.
├── Makefile                  # Deployment automation
├── terraform.tfvars          # Unified configuration
├── state.config              # Backend configuration
├── envs/
│   ├── global/s3/            # S3 backend
│   └── staging/
│       ├── vpc/              # VPC module
│       ├── eks/              # EKS module
│       └── workloads/       # All workloads
```

## References

- [Argo vprofile appp](https://github.com/OchukoWH/argo-project-defs.git)
