#!/bin/bash

# ==============================================================================
# Deploy Infrastructure Script
# Deploys VPC and EKS cluster sequentially
# ==============================================================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get the script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Deploying Infrastructure${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Function to deploy a module
deploy_module() {
    local module_name=$1
    local module_path=$2
    
    echo -e "${YELLOW}Deploying ${module_name}...${NC}"
    echo "Path: ${module_path}"
    
    cd "${module_path}"
    
    echo "Initializing Terraform..."
    terraform init -backend-config="${PROJECT_ROOT}/state.config"
    
    echo "Planning changes..."
    terraform plan -var-file="${PROJECT_ROOT}/terraform.tfvars" -out=tfplan
    
    echo "Applying changes..."
    if terraform apply -auto-approve tfplan; then
        echo -e "${GREEN}✓ ${module_name} deployed successfully${NC}"
        rm -f tfplan
    else
        echo -e "${RED}✗ Failed to deploy ${module_name}${NC}"
        rm -f tfplan
        exit 1
    fi
    
    echo ""
}

# Step 1: Deploy VPC
deploy_module "VPC" "${PROJECT_ROOT}/envs/staging/vpc"

# Step 2: Deploy EKS Cluster
deploy_module "EKS Cluster" "${PROJECT_ROOT}/envs/staging/eks"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Infrastructure deployment completed!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Next steps:"
echo "1. Update kubeconfig: aws eks update-kubeconfig --name staging-demo3 --region us-west-2"
echo "2. Verify cluster access: kubectl get nodes"
echo "3. Deploy workloads: ./scripts/deploy-workloads.sh"

