# ==============================================================================
# VProfile EKS Infrastructure Makefile
# ==============================================================================

.PHONY: help init-s3 deploy-s3 migrate-s3-backend deploy-vpc deploy-eks deploy-infrastructure \
	deploy-workloads deploy-all destroy-all destroy-workloads destroy-infrastructure \
	plan-vpc plan-eks plan-workloads update-kubeconfig verify-cluster \
	deploy-metrics-server deploy-cluster-autoscaler deploy-aws-lbc deploy-nginx-ingress \
	deploy-cert-manager deploy-cluster-issuer deploy-ebs-csi-driver deploy-efs-csi-driver \
	deploy-argocd deploy-argocd-ingress deploy-vprofile-app \
	clean

# Variables
TFVARS := terraform.tfvars
STATE_CONFIG := state.config
S3_DIR := envs/global/s3
VPC_DIR := envs/staging/vpc
EKS_DIR := envs/staging/eks
WORKLOADS_DIR := envs/staging/workloads

# Colors for output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
BLUE := \033[0;34m
NC := \033[0m

# Workloads in deployment order
WORKLOADS := metrics-server cluster-autoscaler aws-lbc nginx-ingress cert-manager \
	ebs-csi-driver efs-csi-driver argocd argocd-ingress vprofile-app

# ==============================================================================
# Help Target
# ==============================================================================
help:
	@echo "$(GREEN)VProfile EKS Infrastructure Deployment$(NC)"
	@echo ""
	@echo "$(YELLOW)Infrastructure Targets:$(NC)"
	@echo "  make init-s3              - Initialize S3 backend (first time only)"
	@echo "  make deploy-s3            - Deploy S3 backend"
	@echo "  make migrate-s3-backend   - Migrate S3 backend state to S3"
	@echo "  make deploy-vpc           - Deploy VPC infrastructure"
	@echo "  make deploy-eks           - Deploy EKS cluster"
	@echo "  make deploy-infrastructure - Deploy VPC and EKS sequentially"
	@echo ""
	@echo "$(YELLOW)Workload Targets:$(NC)"
	@echo "  make deploy-workloads      - Deploy all workloads sequentially"
	@echo "  make deploy-all           - Deploy infrastructure + workloads"
	@echo ""
	@echo "$(YELLOW)Individual Workload Targets:$(NC)"
	@echo "  make deploy-metrics-server    - Deploy metrics-server"
	@echo "  make deploy-cluster-autoscaler - Deploy cluster-autoscaler"
	@echo "  make deploy-aws-lbc           - Deploy AWS Load Balancer Controller"
	@echo "  make deploy-nginx-ingress     - Deploy nginx-ingress"
	@echo "  make deploy-cert-manager      - Deploy cert-manager"
	@echo "  make deploy-cluster-issuer   - Deploy cluster-issuer"
	@echo "  make deploy-ebs-csi-driver   - Deploy EBS CSI driver"
	@echo "  make deploy-efs-csi-driver    - Deploy EFS CSI driver"
	@echo "  make deploy-argocd            - Deploy ArgoCD"
	@echo "  make deploy-argocd-ingress    - Deploy ArgoCD ingress"
	@echo "  make deploy-vprofile-app      - Deploy vprofile-app"
	@echo ""
	@echo "$(YELLOW)Planning Targets:$(NC)"
	@echo "  make plan-vpc             - Plan VPC changes"
	@echo "  make plan-eks             - Plan EKS changes"
	@echo "  make plan-workloads       - Plan all workload changes"
	@echo ""
	@echo "$(YELLOW)Destruction Targets:$(NC)"
	@echo "  make destroy-workloads    - Destroy all workloads"
	@echo "  make destroy-infrastructure - Destroy VPC and EKS"
	@echo "  make destroy-all         - Destroy everything"
	@echo ""
	@echo "$(YELLOW)Utility Targets:$(NC)"
	@echo "  make update-kubeconfig    - Update kubectl config for cluster"
	@echo "  make verify-cluster      - Verify cluster access"
	@echo "  make clean                - Clean Terraform plan files"

# ==============================================================================
# S3 Backend Setup
# ==============================================================================
init-s3:
	@echo "$(GREEN)Initializing S3 backend...$(NC)"
	@cd $(S3_DIR) && terraform init -backend-config=../../../$(STATE_CONFIG)

deploy-s3:
	@echo "$(GREEN)Deploying S3 backend...$(NC)"
	@cd $(S3_DIR) && \
		terraform init && \
		terraform plan -compact-warnings -var-file=../../../$(TFVARS) -out=tfplan && \
		terraform apply -auto-approve tfplan && \
		rm -f tfplan
	@echo "$(GREEN)✓ S3 backend deployed$(NC)"
	@echo ""
	@echo "$(YELLOW)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo "$(YELLOW)IMPORTANT: Before migrating to S3 backend:$(NC)"
	@echo "$(YELLOW)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo "$(BLUE)1. Uncomment the backend configuration in:$(NC)"
	@echo "   $(S3_DIR)/state.tf"
	@echo ""
	@echo "$(BLUE)2. Then run:$(NC)"
	@echo "   make migrate-s3-backend"
	@echo "$(YELLOW)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"

migrate-s3-backend:
	@echo "$(GREEN)Migrating S3 backend state...$(NC)"
	@cd $(S3_DIR) && \
		echo "yes" | terraform init -input=false -migrate-state -backend-config=../../../$(STATE_CONFIG)
	@echo "$(GREEN)✓ S3 backend state migrated$(NC)"

# ==============================================================================
# Infrastructure Deployment
# ==============================================================================
deploy-vpc:
	@echo "$(GREEN)Deploying VPC...$(NC)"
	@cd $(VPC_DIR) && \
		terraform init -backend-config=../../../$(STATE_CONFIG) && \
		terraform plan -compact-warnings -var-file=../../../$(TFVARS) -out=tfplan && \
		terraform apply -auto-approve tfplan && \
		rm -f tfplan
	@echo "$(GREEN)✓ VPC deployed successfully$(NC)"

deploy-eks:
	@echo "$(GREEN)Deploying EKS cluster...$(NC)"
	@cd $(EKS_DIR) && \
		terraform init -backend-config=../../../$(STATE_CONFIG) && \
		terraform plan -compact-warnings -var-file=../../../$(TFVARS) -out=tfplan && \
		terraform apply -auto-approve tfplan && \
		rm -f tfplan
	@echo "$(GREEN)✓ EKS cluster deployed successfully$(NC)"

deploy-infrastructure: deploy-vpc deploy-eks
	@echo "$(GREEN)========================================$(NC)"
	@echo "$(GREEN)Infrastructure deployment completed!$(NC)"
	@echo "$(GREEN)========================================$(NC)"
	@echo ""
	@echo "Next steps:"
	@echo "  1. Update kubeconfig: make update-kubeconfig"
	@echo "  2. Verify cluster: make verify-cluster"
	@echo "  3. Deploy workloads: make deploy-workloads"

# ==============================================================================
# Workload Deployment
# ==============================================================================
define deploy-workload
	@echo "$(BLUE)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo "$(YELLOW)Deploying $(1)...$(NC)"
	@cd $(WORKLOADS_DIR)/$(1) && \
		terraform init -backend-config=../../../../$(STATE_CONFIG) && \
		terraform plan -compact-warnings -var-file=../../../../$(TFVARS) -out=tfplan && \
		terraform apply -auto-approve tfplan && \
		rm -f tfplan
	@echo "$(GREEN)✓ $(1) deployed successfully$(NC)"
	@echo ""
endef

deploy-workloads:
	@echo "$(GREEN)========================================$(NC)"
	@echo "$(GREEN)Deploying EKS Workloads$(NC)"
	@echo "$(GREEN)========================================$(NC)"
	@echo ""
	$(call deploy-workload,metrics-server)
	$(call deploy-workload,cluster-autoscaler)
	$(call deploy-workload,aws-lbc)
	$(call deploy-workload,nginx-ingress)
	$(call deploy-workload,cert-manager)
	$(call deploy-workload,ebs-csi-driver)
	$(call deploy-workload,efs-csi-driver)
	$(call deploy-workload,argocd)
	$(call deploy-workload,cluster-issuer)
	$(call deploy-workload,argocd-ingress)
	$(call deploy-workload,vprofile-app)
	@echo "$(GREEN)========================================$(NC)"
	@echo "$(GREEN)All workloads deployed successfully!$(NC)"
	@echo "$(GREEN)========================================$(NC)"
	@echo ""
	@echo "Verification commands:"
	@echo "  kubectl get pods --all-namespaces"
	@echo "  kubectl get ingress -n argocd"
	@echo "  kubectl get certificate -n argocd"
	@echo "  kubectl get application -n argocd"

deploy-all: deploy-infrastructure update-kubeconfig verify-cluster deploy-workloads
	@echo "$(GREEN)========================================$(NC)"
	@echo "$(GREEN)Complete deployment finished!$(NC)"
	@echo "$(GREEN)========================================$(NC)"

# ==============================================================================
# Individual Workload Deployment Targets
# ==============================================================================
deploy-metrics-server:
	$(call deploy-workload,metrics-server)

deploy-cluster-autoscaler:
	$(call deploy-workload,cluster-autoscaler)

deploy-aws-lbc:
	$(call deploy-workload,aws-lbc)

deploy-nginx-ingress:
	$(call deploy-workload,nginx-ingress)

deploy-cert-manager:
	$(call deploy-workload,cert-manager)

deploy-cluster-issuer:
	$(call deploy-workload,cluster-issuer)

deploy-ebs-csi-driver:
	$(call deploy-workload,ebs-csi-driver)

deploy-efs-csi-driver:
	$(call deploy-workload,efs-csi-driver)

deploy-argocd:
	$(call deploy-workload,argocd)

deploy-argocd-ingress:
	$(call deploy-workload,argocd-ingress)

deploy-vprofile-app:
	$(call deploy-workload,vprofile-app)

# ==============================================================================
# Planning Targets
# ==============================================================================
plan-vpc:
	@cd $(VPC_DIR) && \
		terraform init -backend-config=../../../$(STATE_CONFIG) && \
		terraform plan -compact-warnings -var-file=../../../$(TFVARS)

plan-eks:
	@cd $(EKS_DIR) && \
		terraform init -backend-config=../../../$(STATE_CONFIG) && \
		terraform plan -compact-warnings -var-file=../../../$(TFVARS)

define plan-workload
	@echo "$(YELLOW)Planning $(1)...$(NC)"
	@cd $(WORKLOADS_DIR)/$(1) && \
		terraform init -backend-config=../../../../$(STATE_CONFIG) && \
		terraform plan -compact-warnings -var-file=../../../../$(TFVARS)
	@echo ""
endef

plan-workloads:
	@echo "$(GREEN)Planning all workloads...$(NC)"
	@echo ""
	$(foreach workload,$(WORKLOADS),$(call plan-workload,$(workload)))

# ==============================================================================
# Destruction Targets
# ==============================================================================
define destroy-workload
	@echo "$(YELLOW)Destroying $(1)...$(NC)"
	@cd $(WORKLOADS_DIR)/$(1) && \
		terraform init -backend-config=../../../../$(STATE_CONFIG) && \
		terraform destroy -compact-warnings -var-file=../../../../$(TFVARS) -auto-approve
	@echo "$(GREEN)✓ $(1) destroyed$(NC)"
	@echo ""
endef

destroy-workloads:
	@echo "$(RED)Destroying all workloads...$(NC)"
	@echo ""
	$(call destroy-workload,vprofile-app)
	$(call destroy-workload,argocd-ingress)
	$(call destroy-workload,argocd)
	$(call destroy-workload,efs-csi-driver)
	$(call destroy-workload,ebs-csi-driver)
	$(call destroy-workload,cluster-issuer)
	$(call destroy-workload,cert-manager)
	$(call destroy-workload,nginx-ingress)
	$(call destroy-workload,aws-lbc)
	$(call destroy-workload,cluster-autoscaler)
	$(call destroy-workload,metrics-server)
	@echo "$(GREEN)All workloads destroyed$(NC)"

destroy-infrastructure:
	@echo "$(RED)Destroying infrastructure...$(NC)"
	@cd $(EKS_DIR) && \
		terraform init -backend-config=../../../$(STATE_CONFIG) && \
		terraform destroy -compact-warnings -var-file=../../../$(TFVARS) -auto-approve
	@cd $(VPC_DIR) && \
		terraform init -backend-config=../../../$(STATE_CONFIG) && \
		terraform destroy -compact-warnings -var-file=../../../$(TFVARS) -auto-approve
	@echo "$(GREEN)Infrastructure destroyed$(NC)"

destroy-all: destroy-workloads destroy-infrastructure
	@echo "$(GREEN)All resources destroyed$(NC)"

# ==============================================================================
# Utility Targets
# ==============================================================================
update-kubeconfig:
	@echo "$(YELLOW)Updating kubectl config...$(NC)"
	@aws eks update-kubeconfig --name staging-demo3 --region us-west-2
	@echo "$(GREEN)✓ kubectl config updated$(NC)"

verify-cluster:
	@echo "$(YELLOW)Verifying cluster access...$(NC)"
	@kubectl get nodes || (echo "$(RED)✗ Failed to connect to cluster$(NC)" && exit 1)
	@echo "$(GREEN)✓ Cluster access verified$(NC)"

clean:
	@echo "$(YELLOW)Cleaning Terraform plan files...$(NC)"
	@find . -name "tfplan" -type f -delete
	@find . -name ".terraform" -type d -exec rm -rf {} + 2>/dev/null || true
	@find . -name ".terraform.lock.hcl" -type f -delete
	@echo "$(GREEN)✓ Cleaned$(NC)"

# ==============================================================================
# Default Target
# ==============================================================================
.DEFAULT_GOAL := help

