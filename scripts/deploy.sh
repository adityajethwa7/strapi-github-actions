#!/bin/bash

# Strapi AWS ECS Fargate Deployment Script
# This script builds the Docker image, pushes it to ECR, and deploys using Terraform

set -e  # Exit on any error

# Configuration
AWS_REGION="us-east-1"
WORKSPACE="dev"
IMAGE_TAG="latest"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if required tools are installed
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install it first."
        exit 1
    fi
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install it first."
        exit 1
    fi
    
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed. Please install it first."
        exit 1
    fi
    
    print_success "All prerequisites are installed."
}

# Function to check AWS credentials
check_aws_credentials() {
    print_status "Checking AWS credentials..."
    
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials are not configured. Please run 'aws configure' first."
        exit 1
    fi
    
    print_success "AWS credentials are configured."
}

# Function to initialize Terraform
init_terraform() {
    print_status "Initializing Terraform..."
    
    cd terraform
    terraform init
    terraform workspace select $WORKSPACE || terraform workspace new $WORKSPACE
    cd ..
    
    print_success "Terraform initialized and workspace '$WORKSPACE' selected."
}

# Function to get ECR repository URL
get_ecr_url() {
    print_status "Getting ECR repository URL..."

    cd terraform
    export ECR_URL=$(terraform output -raw ecr_repository_url 2>/dev/null || echo "")
    cd ..

    if [ -z "$ECR_URL" ]; then
        print_warning "ECR repository not found. Will create it with Terraform."
        return 1
    fi

    print_success "ECR repository URL: $ECR_URL"
    return 0
}

# Function to create ECR repository if it doesn't exist
create_ecr_if_needed() {
    if ! get_ecr_url; then
        print_status "Creating ECR repository with Terraform..."

        cd terraform
        terraform plan -target=aws_ecr_repository.strapi
        terraform apply -target=aws_ecr_repository.strapi -auto-approve
        cd ..

        # Get ECR URL after creation
        if ! get_ecr_url; then
            print_error "Failed to get ECR repository URL after creation."
            exit 1
        fi
    fi
}

# Function to build and push Docker image
build_and_push_image() {
    print_status "Building Docker image..."

    # Build the image
    docker build -t strapi-app:$IMAGE_TAG .

    print_success "Docker image built successfully."

    # Get ECR URL again to ensure it's available
    get_ecr_url

    print_status "Logging into ECR..."

    # Login to ECR
    print_status "Authenticating with ECR repository..."
    aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_URL

    if [ $? -ne 0 ]; then
        print_error "Failed to authenticate with ECR. Please check your AWS credentials."
        exit 1
    fi

    print_success "Logged into ECR successfully."

    print_status "Tagging and pushing image to ECR..."

    # Tag and push the image
    docker tag strapi-app:$IMAGE_TAG $ECR_URL:$IMAGE_TAG
    docker push $ECR_URL:$IMAGE_TAG

    print_success "Image pushed to ECR successfully."
}

# Function to deploy infrastructure with Terraform
deploy_infrastructure() {
    print_status "Deploying infrastructure with Terraform..."
    
    cd terraform
    
    # Plan the deployment
    print_status "Running Terraform plan..."
    terraform plan
    
    # Apply the deployment
    print_status "Applying Terraform configuration..."
    terraform apply -auto-approve
    
    cd ..
    
    print_success "Infrastructure deployed successfully."
}

# Function to get deployment outputs
get_deployment_info() {
    print_status "Getting deployment information..."
    
    cd terraform
    
    ALB_URL=$(terraform output -raw alb_url)
    CLUSTER_NAME=$(terraform output -raw cluster_name)
    
    cd ..
    
    print_success "Deployment completed successfully!"
    echo ""
    echo "=== Deployment Information ==="
    echo "Application URL: $ALB_URL"
    echo "ECS Cluster: $CLUSTER_NAME"
    echo "ECR Repository: $ECR_URL"
    echo "AWS Region: $AWS_REGION"
    echo "Workspace: $WORKSPACE"
    echo ""
    echo "Your Strapi application should be accessible at: $ALB_URL"
    echo "Note: It may take a few minutes for the service to become healthy."
}

# Function to wait for service to be healthy
wait_for_service() {
    print_status "Waiting for ECS service to become healthy..."
    
    cd terraform
    CLUSTER_NAME=$(terraform output -raw cluster_name)
    SERVICE_NAME="strapi-service-$WORKSPACE"
    cd ..
    
    print_status "Checking service status..."
    
    # Wait for service to stabilize (max 10 minutes)
    timeout=600
    elapsed=0
    interval=30
    
    while [ $elapsed -lt $timeout ]; do
        status=$(aws ecs describe-services \
            --cluster $CLUSTER_NAME \
            --services $SERVICE_NAME \
            --region $AWS_REGION \
            --query 'services[0].deployments[0].status' \
            --output text 2>/dev/null || echo "UNKNOWN")
        
        if [ "$status" = "PRIMARY" ]; then
            print_success "Service is running and healthy!"
            return 0
        fi
        
        print_status "Service status: $status. Waiting..."
        sleep $interval
        elapsed=$((elapsed + interval))
    done
    
    print_warning "Service deployment is taking longer than expected. Check AWS console for details."
}

# Main deployment function
main() {
    echo "=== Strapi AWS ECS Fargate Deployment ==="
    echo ""
    
    check_prerequisites
    check_aws_credentials
    init_terraform
    create_ecr_if_needed
    build_and_push_image
    deploy_infrastructure
    wait_for_service
    get_deployment_info
    
    print_success "Deployment script completed!"
}

# Run main function
main "$@"
