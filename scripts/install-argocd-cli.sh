#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
ARGOCD_PORT=8080
ARGOCD_NAMESPACE="argocd"
ARGOCD_SERVER="localhost:${ARGOCD_PORT}"
ARGOCD_USERNAME="admin"

echo -e "${GREEN}=== ArgoCD CLI Installation and Login Script ===${NC}\n"

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to detect OS
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
    else
        echo "unknown"
    fi
}

# Function to install ArgoCD CLI on macOS
install_argocd_macos() {
    if command_exists brew; then
        echo -e "${YELLOW}Installing ArgoCD CLI using Homebrew...${NC}"
        brew install argocd
    else
        echo -e "${RED}Error: Homebrew not found. Please install Homebrew first or install ArgoCD CLI manually.${NC}"
        exit 1
    fi
}

# Function to install ArgoCD CLI on Linux
install_argocd_linux() {
    if command_exists argocd; then
        echo -e "${GREEN}ArgoCD CLI is already installed.${NC}"
        return
    fi

    echo -e "${YELLOW}Installing ArgoCD CLI...${NC}"
    
    # Get latest version
    VERSION=$(curl -s https://api.github.com/repos/argoproj/argo-cd/releases/latest | grep tag_name | cut -d '"' -f 4)
    
    # Download and install
    curl -sSL -o /tmp/argocd-linux-amd64 "https://github.com/argoproj/argo-cd/releases/download/${VERSION}/argocd-linux-amd64"
    
    # Install to /usr/local/bin (requires sudo)
    if sudo cp /tmp/argocd-linux-amd64 /usr/local/bin/argocd; then
        sudo chmod +x /usr/local/bin/argocd
        rm /tmp/argocd-linux-amd64
        echo -e "${GREEN}ArgoCD CLI installed successfully.${NC}"
    else
        echo -e "${RED}Error: Failed to install ArgoCD CLI. Please check permissions.${NC}"
        exit 1
    fi
}

# Function to check if kubectl is available
check_kubectl() {
    if ! command_exists kubectl; then
        echo -e "${RED}Error: kubectl is not installed or not in PATH.${NC}"
        exit 1
    fi
    
    # Check if we can connect to cluster
    if ! kubectl cluster-info &>/dev/null; then
        echo -e "${RED}Error: Cannot connect to Kubernetes cluster.${NC}"
        echo -e "${YELLOW}Please ensure kubectl is configured correctly.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}kubectl is configured and connected.${NC}"
}

# Function to check if ArgoCD namespace exists
check_argocd_namespace() {
    if ! kubectl get namespace "${ARGOCD_NAMESPACE}" &>/dev/null; then
        echo -e "${RED}Error: ArgoCD namespace '${ARGOCD_NAMESPACE}' not found.${NC}"
        echo -e "${YELLOW}Please ensure ArgoCD is installed in the cluster.${NC}"
        exit 1
    fi
}

# Function to start port-forward in background
start_port_forward() {
    echo -e "${YELLOW}Starting port-forward to ArgoCD server...${NC}"
    
    # Check if port is already in use
    if lsof -Pi :${ARGOCD_PORT} -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo -e "${YELLOW}Port ${ARGOCD_PORT} is already in use. Assuming port-forward is running.${NC}"
        return 0
    fi
    
    # Start port-forward in background
    kubectl port-forward svc/argocd-server ${ARGOCD_PORT}:80 -n ${ARGOCD_NAMESPACE} > /dev/null 2>&1 &
    PORT_FORWARD_PID=$!
    
    # Wait a moment for port-forward to establish
    sleep 3
    
    # Check if port-forward is still running
    if ! kill -0 $PORT_FORWARD_PID 2>/dev/null; then
        echo -e "${RED}Error: Port-forward failed to start.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Port-forward started (PID: ${PORT_FORWARD_PID})${NC}"
    echo -e "${YELLOW}Note: Port-forward will run in background. Use 'kill ${PORT_FORWARD_PID}' to stop it.${NC}\n"
}

# Function to get ArgoCD admin password
get_argocd_password() {
    echo -e "${YELLOW}Retrieving ArgoCD admin password...${NC}"
    
    # Wait for ArgoCD to be ready
    echo -e "${YELLOW}Waiting for ArgoCD secret to be available...${NC}"
    for i in {1..30}; do
        if kubectl get secret argocd-initial-admin-secret -n ${ARGOCD_NAMESPACE} &>/dev/null; then
            break
        fi
        if [ $i -eq 30 ]; then
            echo -e "${RED}Error: ArgoCD initial admin secret not found after 30 seconds.${NC}"
            exit 1
        fi
        sleep 1
    done
    
    # Get password from secret
    ARGOCD_PASSWORD=$(kubectl -n ${ARGOCD_NAMESPACE} get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d 2>/dev/null || base64 -D 2>/dev/null)
    
    if [ -z "$ARGOCD_PASSWORD" ]; then
        echo -e "${RED}Error: Failed to retrieve ArgoCD password.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}ArgoCD password retrieved successfully.${NC}\n"
}

# Function to login to ArgoCD
login_argocd() {
    echo -e "${YELLOW}Logging in to ArgoCD...${NC}"
    
    # Wait for ArgoCD server to be accessible
    echo -e "${YELLOW}Waiting for ArgoCD server to be accessible...${NC}"
    for i in {1..30}; do
        if curl -s -k "http://${ARGOCD_SERVER}" > /dev/null 2>&1; then
            break
        fi
        if [ $i -eq 30 ]; then
            echo -e "${RED}Error: ArgoCD server not accessible after 30 seconds.${NC}"
            echo -e "${YELLOW}Please ensure port-forward is running.${NC}"
            exit 1
        fi
        sleep 1
    done
    
    # Login to ArgoCD
    if argocd login ${ARGOCD_SERVER} --username ${ARGOCD_USERNAME} --password "${ARGOCD_PASSWORD}" --insecure --grpc-web; then
        echo -e "${GREEN}Successfully logged in to ArgoCD!${NC}\n"
    else
        echo -e "${RED}Error: Failed to login to ArgoCD.${NC}"
        exit 1
    fi
}

# Function to display connection info
display_info() {
    echo -e "${GREEN}=== ArgoCD Connection Information ===${NC}"
    echo -e "Username: ${ARGOCD_USERNAME}"
    echo -e "Password: ${ARGOCD_PASSWORD}"
    echo -e "Server: http://${ARGOCD_SERVER}"
    echo -e "UI URL: http://localhost:${ARGOCD_PORT}"
    echo -e ""
    echo -e "${YELLOW}To change the password, run:${NC}"
    echo -e "  argocd account update-password"
    echo -e ""
    echo -e "${YELLOW}To stop the port-forward, run:${NC}"
    if [ ! -z "$PORT_FORWARD_PID" ]; then
        echo -e "  kill ${PORT_FORWARD_PID}"
    else
        echo -e "  pkill -f 'kubectl port-forward.*argocd-server'"
    fi
    echo ""
}

# Main execution
main() {
    # Detect OS
    OS=$(detect_os)
    
    # Install ArgoCD CLI
    if ! command_exists argocd; then
        echo -e "${YELLOW}ArgoCD CLI not found. Installing...${NC}"
        case $OS in
            macos)
                install_argocd_macos
                ;;
            linux)
                install_argocd_linux
                ;;
            *)
                echo -e "${RED}Error: Unsupported OS. Please install ArgoCD CLI manually.${NC}"
                exit 1
                ;;
        esac
    else
        echo -e "${GREEN}ArgoCD CLI is already installed.${NC}\n"
    fi
    
    # Verify ArgoCD version
    ARGOCD_VERSION=$(argocd version --client --short 2>/dev/null | head -n 1 || echo "unknown")
    echo -e "${GREEN}ArgoCD CLI version: ${ARGOCD_VERSION}${NC}\n"
    
    # Check prerequisites
    check_kubectl
    check_argocd_namespace
    
    # Start port-forward
    start_port_forward
    
    # Get password
    get_argocd_password
    
    # Login
    login_argocd
    
    # Display info
    display_info
    
    echo -e "${GREEN}=== Setup Complete ===${NC}"
}

# Trap to cleanup port-forward on script exit
cleanup() {
    if [ ! -z "$PORT_FORWARD_PID" ]; then
        echo -e "\n${YELLOW}Cleaning up port-forward (PID: ${PORT_FORWARD_PID})...${NC}"
        kill $PORT_FORWARD_PID 2>/dev/null || true
    fi
}
trap cleanup EXIT

# Run main function
main "$@"

