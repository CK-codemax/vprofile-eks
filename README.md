# VProfile EKS Infrastructure

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

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) >= 1.0
- [AWS CLI](https://aws.amazon.com/cli/) installed and configured
- [kubectl](https://kubernetes.io/docs/tasks/tools/) installed
- [Helm](https://helm.sh/docs/intro/install/) 3.x installed

## Quick Start

```bash
# 1. Deploy S3 backend
make deploy-s3

# 2. Deploy infrastructure (VPC + EKS)
make deploy-infrastructure

# 3. Update kubectl config
make update-kubeconfig
make verify-cluster

# 4. Deploy all workloads
make deploy-workloads

# Or deploy everything:
make deploy-all
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
2. **For Applications**: Point your application domains to the Nginx Ingress Controller load balancer address

**Important**: 
- Use **CNAME** records pointing to the load balancer hostname (recommended)
- Or use **A** records with the load balancer IP address
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

- [Argo vprofile appp](https://github.com/CK-codemax/argo-project-defs.git)
