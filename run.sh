#!/bin/bash

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
CLOUD_PROVIDER="aws"
DOCKER_REGISTRY=""
IMAGE_NAME="mini-linux"
IMAGE_TAG="latest"
SKIP_TERRAFORM=false
SKIP_DOCKER=false
SKIP_KUBERNETES=false
USE_LOCAL_REGISTRY=false

# Function to display usage information
usage() {
    echo -e "${BLUE}Kubernetes Mini-Linux Deployment Script${NC}"
    echo
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  -p, --provider PROVIDER     Cloud provider (aws, gcp, azure). Default: aws"
    echo "  -r, --registry REGISTRY     Docker registry URL (e.g., your-username)"
    echo "  -n, --name NAME             Docker image name. Default: mini-linux"
    echo "  -t, --tag TAG               Docker image tag. Default: latest"
    echo "  --skip-terraform            Skip Terraform infrastructure provisioning"
    echo "  --skip-docker               Skip Docker image building and pushing"
    echo "  --skip-kubernetes           Skip Kubernetes manifests deployment"
    echo "  --local-registry            Use local registry (skip Docker Hub push)"
    echo "  -h, --help                  Display this help message"
    echo
    exit 1
}

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--provider)
            CLOUD_PROVIDER="$2"
            shift 2
            ;;
        -r|--registry)
            DOCKER_REGISTRY="$2"
            shift 2
            ;;
        -n|--name)
            IMAGE_NAME="$2"
            shift 2
            ;;
        -t|--tag)
            IMAGE_TAG="$2"
            shift 2
            ;;
        --skip-terraform)
            SKIP_TERRAFORM=true
            shift
            ;;
        --skip-docker)
            SKIP_DOCKER=true
            shift
            ;;
        --skip-kubernetes)
            SKIP_KUBERNETES=true
            shift
            ;;
        --local-registry)
            USE_LOCAL_REGISTRY=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo -e "${RED}Error: Unknown option $1${NC}"
            usage
            ;;
    esac
done

# Check if Docker registry is provided when building Docker images
if [[ "$SKIP_DOCKER" == "false" && "$USE_LOCAL_REGISTRY" == "false" && -z "$DOCKER_REGISTRY" ]]; then
    echo -e "${RED}Error: Docker registry is required for building and pushing images.${NC}"
    echo -e "${YELLOW}Please provide a registry using -r or --registry option or use --local-registry to skip pushing.${NC}"
    exit 1
fi

# Validate cloud provider
if [[ "$CLOUD_PROVIDER" != "aws" && "$CLOUD_PROVIDER" != "gcp" && "$CLOUD_PROVIDER" != "azure" ]]; then
    echo -e "${RED}Error: Invalid cloud provider '$CLOUD_PROVIDER'.${NC}"
    echo -e "${YELLOW}Valid options are: aws, gcp, azure${NC}"
    exit 1
fi

# Function to display section header
section() {
    echo
    echo -e "${BLUE}=== $1 ===${NC}"
    echo
}

# Function to check if command succeeded
check_error() {
    if [ $? -ne 0 ]; then
        echo -e "${RED}Error: $1${NC}"
        exit 1
    fi
}

# Function to run Terraform commands using Docker
terraform_cmd() {
    docker run --rm -v "$(pwd):/workspace" -w /workspace hashicorp/terraform:latest "$@"
}

# Function to create terraform.tfvars file
create_tfvars() {
    section "Creating Terraform Variables File"
    
    # Create terraform.tfvars file
    cat > terraform/terraform.tfvars <<EOF
cloud_provider = "$CLOUD_PROVIDER"
prefix = "mini-linux"
environment = "demo"
EOF

    # Add cloud-specific variables based on provider
    case $CLOUD_PROVIDER in
        aws)
            # Ask for AWS region if not specified
            read -p "Enter AWS region (default: us-west-2): " AWS_REGION
            AWS_REGION=${AWS_REGION:-us-west-2}
            echo "aws_region = \"$AWS_REGION\"" >> terraform/terraform.tfvars
            ;;
        gcp)
            # Ask for GCP project and region if not specified
            read -p "Enter GCP project ID: " GCP_PROJECT
            if [[ -z "$GCP_PROJECT" ]]; then
                echo -e "${RED}Error: GCP project ID is required.${NC}"
                exit 1
            fi
            
            read -p "Enter GCP region (default: us-central1): " GCP_REGION
            GCP_REGION=${GCP_REGION:-us-central1}
            
            echo "gcp_project = \"$GCP_PROJECT\"" >> terraform/terraform.tfvars
            echo "gcp_region = \"$GCP_REGION\"" >> terraform/terraform.tfvars
            ;;
        azure)
            # Ask for Azure location if not specified
            read -p "Enter Azure location (default: eastus): " AZURE_LOCATION
            AZURE_LOCATION=${AZURE_LOCATION:-eastus}
            echo "azure_location = \"$AZURE_LOCATION\"" >> terraform/terraform.tfvars
            ;;
    esac
    
    echo -e "${GREEN}Terraform variables file created successfully.${NC}"
}

# Check if we can use kubectl
check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        echo -e "${RED}Error: kubectl is not installed or not in your PATH.${NC}"
        echo -e "${YELLOW}Please install kubectl: https://kubernetes.io/docs/tasks/tools/${NC}"
        exit 1
    fi
}

# 1. Terraform Infrastructure Provisioning
if [[ "$SKIP_TERRAFORM" == "false" ]]; then
    # Check if Docker is available
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}Error: Docker is not installed or not in your PATH.${NC}"
        echo -e "${YELLOW}Please install Docker: https://docs.docker.com/get-docker/${NC}"
        exit 1
    fi
    
    # Pull Terraform Docker image
    section "Pulling Terraform Docker Image"
    docker pull hashicorp/terraform:latest
    check_error "Failed to pull Terraform Docker image"
    
    # Create terraform.tfvars file
    create_tfvars
    
    # Initialize Terraform
    section "Initializing Terraform"
    cd terraform
    terraform_cmd init
    check_error "Failed to initialize Terraform"
    echo -e "${GREEN}Terraform initialized successfully.${NC}"
    
    # Create Terraform plan
    section "Creating Terraform Plan"
    terraform_cmd plan -out=tfplan
    check_error "Failed to create Terraform plan"
    echo -e "${GREEN}Terraform plan created successfully.${NC}"
    
    # Apply Terraform plan
    section "Applying Terraform Plan (Creating Kubernetes Cluster)"
    echo -e "${YELLOW}This may take several minutes...${NC}"
    terraform_cmd apply -auto-approve tfplan
    check_error "Failed to apply Terraform plan"
    echo -e "${GREEN}Kubernetes cluster created successfully.${NC}"
    
    # Get kubeconfig
    section "Configuring kubectl"
    terraform_cmd output -raw kubeconfig > ../kubeconfig.yaml
    check_error "Failed to get kubeconfig"
    export KUBECONFIG=$(pwd)/../kubeconfig.yaml
    echo -e "${GREEN}kubectl configured successfully.${NC}"
    
    cd ..
else
    echo -e "${YELLOW}Skipping Terraform infrastructure provisioning.${NC}"
    
    # Check if kubeconfig exists
    if [[ -f "kubeconfig.yaml" ]]; then
        export KUBECONFIG=$(pwd)/kubeconfig.yaml
    else
        echo -e "${YELLOW}Using existing kubectl configuration.${NC}"
    fi
fi

# 2. Docker Image Building and Pushing
if [[ "$SKIP_DOCKER" == "false" ]]; then
    section "Building Docker Image"
    cd docker
    docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .
    check_error "Failed to build Docker image"
    echo -e "${GREEN}Docker image built successfully.${NC}"
    
    if [[ "$USE_LOCAL_REGISTRY" == "false" ]]; then
        section "Logging in to Docker Registry"
        echo -e "${YELLOW}You'll need to enter your Docker Hub credentials${NC}"
        docker login
        check_error "Failed to log in to Docker registry"
        
        section "Pushing Docker Image to Registry"
        docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${DOCKER_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}
        docker push ${DOCKER_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}
        check_error "Failed to push Docker image to registry"
        echo -e "${GREEN}Docker image pushed to registry successfully.${NC}"
    else
        echo -e "${YELLOW}Skipping Docker image push (using local registry).${NC}"
    fi
    
    cd ..
else
    echo -e "${YELLOW}Skipping Docker image building and pushing.${NC}"
fi

# 3. Kubernetes Deployment
if [[ "$SKIP_KUBERNETES" == "false" ]]; then
    section "Checking Kubernetes Configuration"
    check_kubectl
    
    # Test kubectl connection
    if ! kubectl get nodes &> /dev/null; then
        echo -e "${RED}Error: Cannot connect to Kubernetes cluster.${NC}"
        echo -e "${YELLOW}Please check your kubeconfig or cluster status.${NC}"
        echo -e "${YELLOW}You can use minikube for local testing: https://minikube.sigs.k8s.io/docs/start/${NC}"
        exit 1
    fi
    
    section "Deploying to Kubernetes"
    
    # Set the image reference based on whether we're using a local or remote registry
    if [[ "$USE_LOCAL_REGISTRY" == "true" ]]; then
        IMAGE_REF="${IMAGE_NAME}:${IMAGE_TAG}"
    else
        IMAGE_REF="${DOCKER_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
    fi
    
    # Replace the image registry in the Kubernetes manifest
    sed "s|\${DOCKER_REGISTRY}/mini-linux:latest|${IMAGE_REF}|g" kubernetes/mini-linux-deployment.yaml > kubernetes/deployment.yaml
    
    # Apply Kubernetes manifests
    kubectl apply -f kubernetes/deployment.yaml
    check_error "Failed to apply Kubernetes manifests"
    echo -e "${GREEN}Kubernetes deployment created successfully.${NC}"
    
    # Wait for pods to be ready
    echo -e "${YELLOW}Waiting for pods to be ready...${NC}"
    kubectl -n mini-linux wait --for=condition=ready pod --selector=app=mini-linux --timeout=300s
    
    if [ $? -ne 0 ]; then
        echo -e "${YELLOW}Pods did not become ready within timeout. Check status manually:${NC}"
        kubectl -n mini-linux get pods -l app=mini-linux
    else
        # Get deployment information
        section "Deployment Information"
        echo -e "${GREEN}Pods:${NC}"
        kubectl -n mini-linux get pods -l app=mini-linux
        
        echo -e "\n${GREEN}Service:${NC}"
        kubectl -n mini-linux get service mini-linux-service
        
        # Instructions for accessing the service
        section "Access Instructions"
        echo -e "To port-forward the mini-Linux service to your local machine, run:"
        echo -e "  ${YELLOW}kubectl -n mini-linux port-forward svc/mini-linux-service 8080:80${NC}"
        echo -e "Then access it at: ${GREEN}http://localhost:8080${NC}"
        
        echo -e "\nTo access the mini-Linux container shell, run:"
        echo -e "  ${YELLOW}kubectl -n mini-linux exec -it \$(kubectl -n mini-linux get pod -l app=mini-linux -o jsonpath='{.items[0].metadata.name}') -- /bin/sh${NC}"
    fi
else
    echo -e "${YELLOW}Skipping Kubernetes deployment.${NC}"
fi

section "Deployment Complete"
echo -e "${GREEN}Mini-Linux deployment to Kubernetes has been completed (or attempted).${NC}"
echo -e "${YELLOW}Check the output above for any warnings or manual steps needed.${NC}"