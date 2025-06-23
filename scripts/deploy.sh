#!/bin/bash

# Script untuk deploy aplikasi Kubernetes dengan HPA
# Author: Dafa Ardiansyah
# Description: Deploy nginx dengan Horizontal Pod Autoscaler

set -e  # Exit on any error

echo "🚀 Starting Kubernetes deployment with HPA..."

# Function untuk check apakah kubectl tersedia
check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        echo "❌ kubectl tidak ditemukan. Pastikan kubectl sudah terinstall."
        exit 1
    fi
    echo "✅ kubectl ditemukan"
}

# Function untuk check cluster connection
check_cluster() {
    if ! kubectl cluster-info &> /dev/null; then
        echo "❌ Tidak bisa connect ke Kubernetes cluster"
        exit 1
    fi
    echo "✅ Connected to Kubernetes cluster"
}

# Function untuk check metrics server
check_metrics_server() {
    if ! kubectl get deployment metrics-server -n kube-system &> /dev/null; then
        echo "⚠️  Metrics server tidak ditemukan. HPA membutuhkan metrics server."
        echo "   Install metrics server dengan: kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml"
        read -p "   Lanjutkan deployment? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        echo "✅ Metrics server ditemukan"
    fi
}

# Function untuk deploy manifests
deploy_manifests() {
    echo "📦 Deploying manifests..."
    
    # Deploy deployment
    echo "   Deploying nginx deployment..."
    kubectl apply -f manifests/deployment.yaml
    
    # Deploy service
    echo "   Deploying nginx service..."
    kubectl apply -f manifests/service.yaml
    
    # Wait for deployment to be ready
    echo "   Waiting for deployment to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/nginx-deployment
    
    # Deploy HPA
    echo "   Deploying HPA..."
    kubectl apply -f manifests/hpa.yaml
    
    echo "✅ All manifests deployed successfully!"
}

# Function untuk show status
show_status() {
    echo "📊 Current status:"
    echo "\n--- Deployments ---"
    kubectl get deployments
    echo "\n--- Pods ---"
    kubectl get pods
    echo "\n--- Services ---"
    kubectl get services
    echo "\n--- HPA ---"
    kubectl get hpa
}

# Main execution
main() {
    check_kubectl
    check_cluster
    check_metrics_server
    deploy_manifests
    show_status
    
    echo "\n🎉 Deployment completed!"
    echo "\n📝 Useful commands:"
    echo "   Monitor HPA: kubectl get hpa -w"
    echo "   Describe HPA: kubectl describe hpa nginx-hpa"
    echo "   Check pods: kubectl get pods -w"
    echo "   Access nginx: kubectl port-forward service/nginx-service 8080:80"
    echo "   Load test: kubectl apply -f manifests/load-test.yaml"
}

# Run main function
main