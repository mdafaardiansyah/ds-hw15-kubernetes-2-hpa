#!/bin/bash

# Script untuk cleanup/uninstall aplikasi Kubernetes
# Author: Dafa Ardiansyah
# Description: Remove nginx deployment dan HPA

set -e  # Exit on any error

echo "🧹 Starting cleanup process..."

# Function untuk cleanup manifests
cleanup_manifests() {
    echo "🗑️  Removing manifests..."
    
    # Remove HPA first
    echo "   Removing HPA..."
    kubectl delete -f manifests/hpa.yaml --ignore-not-found=true
    
    # Remove services
    echo "   Removing services..."
    kubectl delete -f manifests/service.yaml --ignore-not-found=true
    
    # Remove deployment
    echo "   Removing deployment..."
    kubectl delete -f manifests/deployment.yaml --ignore-not-found=true
    
    # Remove load test pods if exists
    echo "   Removing load test pods..."
    kubectl delete -f manifests/load-test.yaml --ignore-not-found=true
    
    echo "✅ All resources removed successfully!"
}

# Function untuk show remaining resources
show_remaining() {
    echo "📊 Checking remaining resources:"
    echo "\n--- Deployments ---"
    kubectl get deployments | grep nginx || echo "No nginx deployments found"
    echo "\n--- Pods ---"
    kubectl get pods | grep nginx || echo "No nginx pods found"
    echo "\n--- Services ---"
    kubectl get services | grep nginx || echo "No nginx services found"
    echo "\n--- HPA ---"
    kubectl get hpa | grep nginx || echo "No nginx HPA found"
}

# Main execution
main() {
    cleanup_manifests
    show_remaining
    
    echo "\n🎉 Cleanup completed!"
}

# Run main function
main