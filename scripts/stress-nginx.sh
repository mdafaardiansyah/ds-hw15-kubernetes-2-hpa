#!/bin/bash

# Script untuk melakukan stress test pada nginx pods
# Tujuan: Meningkatkan memory usage untuk memicu HPA scaling

echo "🔥 Starting intensive stress test on nginx pods..."

# Get nginx pod names
NGINX_PODS=$(kubectl get pods -l app=nginx -o jsonpath='{.items[*].metadata.name}')

echo "📋 Found nginx pods: $NGINX_PODS"

# Function to stress test a pod
stress_pod() {
    local pod_name=$1
    echo "⚡ Stressing pod: $pod_name"
    
    # Execute stress commands in the pod
    kubectl exec $pod_name -- /bin/sh -c "
        # Create memory load files
        dd if=/dev/zero of=/tmp/memload1 bs=1M count=40 2>/dev/null &
        dd if=/dev/zero of=/tmp/memload2 bs=1M count=30 2>/dev/null &
        
        # Create CPU load
        yes > /dev/null &
        yes > /dev/null &
        
        # Keep processes running
        sleep 180
    " &
}

# Stress all nginx pods
for pod in $NGINX_PODS; do
    stress_pod $pod
done

echo "🚀 Stress test started on all nginx pods"
echo "📊 Monitor with: kubectl get hpa -w"
echo "📈 Check pod resources: kubectl top pods -l app=nginx"
echo "⏱️  Wait 2-3 minutes for HPA to react"

# Monitor HPA for 3 minutes
echo "\n🔍 Monitoring HPA for 3 minutes..."
for i in {1..18}; do
    echo "\n--- Check $i/18 ($(date)) ---"
    kubectl get hpa nginx-hpa
    kubectl top pods -l app=nginx 2>/dev/null || echo "Metrics not ready yet"
    sleep 10
done

echo "\n✅ Stress test monitoring completed"
echo "🧹 Clean up with: kubectl delete pod --all --force --grace-period=0"