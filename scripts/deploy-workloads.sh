#!/bin/bash

# ==============================================================================
# Deploy Workloads Script
# Deploys all workloads sequentially in the correct order
# ==============================================================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
WORKLOADS_DIR="${PROJECT_ROOT}/envs/staging/workloads"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Deploying EKS Workloads${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Function to deploy a workload
deploy_workload() {
    local workload_name=$1
    local workload_path=$2
    local verify_command=$3
    
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}Deploying ${workload_name}...${NC}"
    echo "Path: ${workload_path}"
    
    cd "${workload_path}"
    
    echo "Initializing Terraform..."
    terraform init -backend-config="${PROJECT_ROOT}/state.config"
    
    echo "Planning changes..."
    terraform plan -var-file="${PROJECT_ROOT}/terraform.tfvars" -out=tfplan
    
    echo "Applying changes..."
    if terraform apply -auto-approve tfplan; then
        echo -e "${GREEN}✓ ${workload_name} deployed successfully${NC}"
        rm -f tfplan
        
        # Verify installation if command provided
        if [ -n "$verify_command" ]; then
            echo "Verifying installation..."
            eval "$verify_command" || echo -e "${YELLOW}Warning: Verification command failed, but deployment succeeded${NC}"
        fi
    else
        echo -e "${RED}✗ Failed to deploy ${workload_name}${NC}"
        rm -f tfplan
        exit 1
    fi
    
    echo ""
}

# Step 5.1: Metrics Server (No dependencies)
deploy_workload "Metrics Server" \
    "${WORKLOADS_DIR}/metrics-server" \
    "kubectl get pods -n metrics-server"

# Step 5.2: Cluster Autoscaler (Depends on: metrics-server)
deploy_workload "Cluster Autoscaler" \
    "${WORKLOADS_DIR}/cluster-autoscaler" \
    "kubectl get pods -n cluster-autoscaler"

# Step 5.3: AWS Load Balancer Controller (Depends on: cluster-autoscaler)
deploy_workload "AWS Load Balancer Controller" \
    "${WORKLOADS_DIR}/aws-lbc" \
    "kubectl get pods -n aws-load-balancer-controller"

# Step 5.4: Nginx Ingress Controller (Depends on: aws-lbc)
deploy_workload "Nginx Ingress Controller" \
    "${WORKLOADS_DIR}/nginx-ingress" \
    "kubectl get pods -n ingress-nginx && kubectl get svc -n ingress-nginx"

# Step 5.5: Cert Manager (Depends on: nginx-ingress)
deploy_workload "Cert Manager" \
    "${WORKLOADS_DIR}/cert-manager" \
    "kubectl get pods -n cert-manager"

# Step 5.6: EBS CSI Driver (No Helm dependencies)
deploy_workload "EBS CSI Driver" \
    "${WORKLOADS_DIR}/ebs-csi-driver" \
    "kubectl get pods -n ebs-csi-driver"

# Step 5.7: EFS CSI Driver (No Helm dependencies)
deploy_workload "EFS CSI Driver" \
    "${WORKLOADS_DIR}/efs-csi-driver" \
    "kubectl get pods -n efs-csi-driver && kubectl get storageclass efs"

# Step 5.8: ArgoCD (Depends on: cert-manager, nginx-ingress)
deploy_workload "ArgoCD" \
    "${WORKLOADS_DIR}/argocd" \
    "kubectl wait --for=condition=Ready pods -l app.kubernetes.io/name=argocd-server -n argocd --timeout=600s && kubectl get pods -n argocd"

# Step 6.1: ArgoCD Ingress (Depends on: argocd, cert-manager, nginx-ingress)
deploy_workload "ArgoCD Ingress" \
    "${WORKLOADS_DIR}/argocd-ingress" \
    "kubectl get ingress -n argocd && kubectl get certificate -n argocd"

# Step 6.2: VProfile Application (Depends on: argocd)
deploy_workload "VProfile Application" \
    "${WORKLOADS_DIR}/vprofile-app" \
    "kubectl get application -n argocd"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}All workloads deployed successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Verification commands:"
echo "  kubectl get pods --all-namespaces"
echo "  kubectl get ingress -n argocd"
echo "  kubectl get certificate -n argocd"
echo "  kubectl get application -n argocd"
echo ""
echo "ArgoCD access:"
echo "  kubectl port-forward svc/argocd-server 8080:80 -n argocd"
echo "  Or via ingress: https://argo.ochukowhoro.xyz"

