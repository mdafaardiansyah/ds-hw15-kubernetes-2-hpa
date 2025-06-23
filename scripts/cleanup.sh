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
    
    # Remove advanced memory load test if exists
    echo "   Removing advanced memory load test..."
    kubectl delete -f manifests/nginx-memory-load.yaml --ignore-not-found=true
    
    echo "✅ All resources removed successfully!"
}

# Function untuk cleanup any remaining test pods
cleanup_test_pods() {
    echo "🧪 Cleaning up test pods..."
    
    # Remove any stress test pods
    echo "   Removing stress test pods..."
    kubectl delete pod memory-stress-test --ignore-not-found=true
    kubectl delete pod http-load-generator --ignore-not-found=true
    kubectl delete pod intensive-load-generator --ignore-not-found=true
    
    # Remove any nginx-memory-load deployments
    echo "   Removing nginx-memory-load deployments..."
    kubectl delete deployment nginx-memory-load --ignore-not-found=true
    
    echo "✅ Test pods cleanup completed!"
}

# Function untuk stop any running stress scripts
stop_stress_scripts() {
    echo "⏹️  Stopping any running stress scripts..."
    
    # Kill any running stress processes
    pkill -f "stress-nginx.sh" || true
    pkill -f "sustained-load.sh" || true
    pkill -f "dd if=/dev/zero" || true
    pkill -f "yes > /dev/null" || true
    
    echo "✅ Stress scripts stopped!"
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
    stop_stress_scripts
    cleanup_manifests
    cleanup_test_pods
    show_remaining
    
    echo "\n🎉 Cleanup completed!"
}

# Run main function
main