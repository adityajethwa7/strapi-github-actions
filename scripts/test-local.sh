#!/bin/bash

# Local Testing Script for Strapi Application
# This script tests the Docker build and runs the container locally

set -e  # Exit on any error

# Configuration
IMAGE_NAME="strapi-app"
IMAGE_TAG="test"
CONTAINER_NAME="strapi-test"
PORT="1337"

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

# Function to check if Docker is running
check_docker() {
    print_status "Checking Docker..."
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install it first."
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        print_error "Docker is not running. Please start Docker first."
        exit 1
    fi
    
    print_success "Docker is running."
}

# Function to clean up existing container
cleanup_container() {
    print_status "Cleaning up existing containers..."
    
    if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        print_status "Stopping and removing existing container: $CONTAINER_NAME"
        docker stop $CONTAINER_NAME 2>/dev/null || true
        docker rm $CONTAINER_NAME 2>/dev/null || true
    fi
    
    print_success "Cleanup completed."
}

# Function to build Docker image
build_image() {
    print_status "Building Docker image..."
    
    docker build -t $IMAGE_NAME:$IMAGE_TAG .
    
    print_success "Docker image built successfully."
}

# Function to run container
run_container() {
    print_status "Starting container..."
    
    docker run -d \
        --name $CONTAINER_NAME \
        -p $PORT:$PORT \
        -e NODE_ENV=production \
        -e HOST=0.0.0.0 \
        -e PORT=$PORT \
        $IMAGE_NAME:$IMAGE_TAG
    
    print_success "Container started successfully."
}

# Function to wait for application to be ready
wait_for_app() {
    print_status "Waiting for application to be ready..."
    
    timeout=120
    elapsed=0
    interval=5
    
    while [ $elapsed -lt $timeout ]; do
        if curl -s -o /dev/null -w "%{http_code}" http://localhost:$PORT | grep -q "200\|404"; then
            print_success "Application is ready!"
            return 0
        fi
        
        print_status "Waiting for application... ($elapsed/$timeout seconds)"
        sleep $interval
        elapsed=$((elapsed + interval))
    done
    
    print_error "Application failed to start within $timeout seconds."
    return 1
}

# Function to show container logs
show_logs() {
    print_status "Container logs:"
    echo "----------------------------------------"
    docker logs $CONTAINER_NAME --tail 20
    echo "----------------------------------------"
}

# Function to test application
test_application() {
    print_status "Testing application endpoints..."
    
    # Test main endpoint
    response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$PORT)
    if [ "$response" = "200" ] || [ "$response" = "404" ]; then
        print_success "Main endpoint responding (HTTP $response)"
    else
        print_error "Main endpoint failed (HTTP $response)"
        return 1
    fi
    
    # Test admin endpoint
    admin_response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$PORT/admin)
    if [ "$admin_response" = "200" ]; then
        print_success "Admin endpoint responding (HTTP $admin_response)"
    else
        print_warning "Admin endpoint returned HTTP $admin_response (this might be normal)"
    fi
    
    print_success "Application tests completed."
}

# Function to display connection info
show_connection_info() {
    print_success "Local testing completed successfully!"
    echo ""
    echo "=== Connection Information ==="
    echo "Application URL: http://localhost:$PORT"
    echo "Admin Panel: http://localhost:$PORT/admin"
    echo "Container Name: $CONTAINER_NAME"
    echo ""
    echo "=== Useful Commands ==="
    echo "View logs: docker logs $CONTAINER_NAME -f"
    echo "Stop container: docker stop $CONTAINER_NAME"
    echo "Remove container: docker rm $CONTAINER_NAME"
    echo ""
    echo "Press Ctrl+C to stop the test and clean up."
}

# Function to cleanup on exit
cleanup_on_exit() {
    print_status "Cleaning up..."
    docker stop $CONTAINER_NAME 2>/dev/null || true
    docker rm $CONTAINER_NAME 2>/dev/null || true
    print_success "Cleanup completed."
}

# Main function
main() {
    echo "=== Strapi Local Testing ==="
    echo ""
    
    # Set up cleanup on exit
    trap cleanup_on_exit EXIT
    
    check_docker
    cleanup_container
    build_image
    run_container
    
    if wait_for_app; then
        test_application
        show_connection_info
        show_logs
        
        # Keep running until user stops
        print_status "Container is running. Press Ctrl+C to stop."
        while true; do
            sleep 10
        done
    else
        print_error "Application failed to start. Showing logs:"
        show_logs
        exit 1
    fi
}

# Run main function
main "$@"
