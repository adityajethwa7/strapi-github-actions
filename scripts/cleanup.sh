#!/bin/bash

# Strapi AWS ECS Fargate Cleanup Script
# This script destroys all AWS resources created by Terraform

set -e  # Exit on any error

# Configuration
AWS_REGION="us-east-1"
WORKSPACE="dev"

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

# Function to confirm destruction
confirm_destruction() {
    print_warning "This will destroy ALL AWS resources created for the Strapi application!"
    print_warning "This includes:"
    echo "  - ECS Cluster and Service"
    echo "  - Application Load Balancer"
    echo "  - ECR Repository and all images"
    echo "  - Security Groups"
    echo "  - IAM Roles"
    echo "  - CloudWatch Log Groups"
    echo ""
    
    read -p "Are you sure you want to continue? (type 'yes' to confirm): " confirmation
    
    if [ "$confirmation" != "yes" ]; then
        print_status "Cleanup cancelled."
        exit 0
    fi
    
    print_warning "Proceeding with cleanup..."
}

# Function to initialize Terraform
init_terraform() {
    print_status "Initializing Terraform..."
    
    cd terraform
    terraform init
    terraform workspace select $WORKSPACE || {
        print_error "Workspace '$WORKSPACE' not found. Nothing to cleanup."
        exit 1
    }
    cd ..
    
    print_success "Terraform initialized and workspace '$WORKSPACE' selected."
}

# Function to destroy infrastructure
destroy_infrastructure() {
    print_status "Destroying infrastructure with Terraform..."
    
    cd terraform
    
    # Show what will be destroyed
    print_status "Running Terraform plan (destroy)..."
    terraform plan -destroy
    
    echo ""
    print_warning "Last chance to cancel! Press Ctrl+C to abort."
    sleep 5
    
    # Destroy the infrastructure
    print_status "Destroying Terraform resources..."
    terraform destroy -auto-approve
    
    cd ..
    
    print_success "Infrastructure destroyed successfully."
}

# Function to clean up local Docker images
cleanup_docker_images() {
    print_status "Cleaning up local Docker images..."
    
    # Remove local Strapi images
    docker images --format "table {{.Repository}}:{{.Tag}}" | grep -E "(strapi-app|strapi)" | while read image; do
        if [ "$image" != "REPOSITORY:TAG" ]; then
            print_status "Removing Docker image: $image"
            docker rmi "$image" 2>/dev/null || print_warning "Could not remove image: $image"
        fi
    done
    
    print_success "Docker cleanup completed."
}

# Function to clean up Terraform state
cleanup_terraform_state() {
    print_status "Cleaning up Terraform workspace..."
    
    cd terraform
    
    # Switch to default workspace and delete the dev workspace
    terraform workspace select default
    terraform workspace delete $WORKSPACE 2>/dev/null || print_warning "Could not delete workspace '$WORKSPACE'"
    
    cd ..
    
    print_success "Terraform workspace cleanup completed."
}

# Main cleanup function
main() {
    echo "=== Strapi AWS ECS Fargate Cleanup ==="
    echo ""
    
    check_prerequisites
    check_aws_credentials
    confirm_destruction
    init_terraform
    destroy_infrastructure
    cleanup_docker_images
    cleanup_terraform_state
    
    print_success "Cleanup completed successfully!"
    echo ""
    echo "All AWS resources have been destroyed."
    echo "Local Docker images have been cleaned up."
    echo "Terraform workspace has been reset."
}

# Run main function
main "$@"
