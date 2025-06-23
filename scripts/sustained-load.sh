#!/bin/bash

# Script untuk membuat sustained memory load yang akan memicu HPA scaling
# Tujuan: Mempertahankan memory usage > 75% selama minimal 60 detik

echo "🔥 Starting SUSTAINED memory load test..."
echo "📊 Target: Keep memory > 75% for 60+ seconds to trigger HPA"

# Get nginx pod names
NGINX_PODS=$(kubectl get pods -l app=nginx -o jsonpath='{.items[*].metadata.name}')
echo "📋 Target pods: $NGINX_PODS"

# Function to create sustained load
create_sustained_load() {
    local pod_name=$1
    echo "⚡ Creating sustained load on: $pod_name"
    
    kubectl exec $pod_name -- /bin/sh -c "
        # Create multiple memory allocations
        dd if=/dev/zero of=/tmp/load1 bs=1M count=45 2>/dev/null &
        dd if=/dev/zero of=/tmp/load2 bs=1M count=35 2>/dev/null &
        
        # Create continuous CPU load to maintain memory pressure
        while true; do
            dd if=/dev/zero of=/tmp/temp bs=1M count=10 2>/dev/null
            rm -f /tmp/temp
            sleep 1
        done
    " &
    
    echo "✅ Sustained load started on $pod_name"
}

# Start sustained load on all pods
for pod in $NGINX_PODS; do
    create_sustained_load $pod
    sleep 2
done

echo "\n🚀 Sustained load test is running..."
echo "📈 This will maintain high memory usage for several minutes"
echo "⏱️  HPA needs 60+ seconds of sustained load to scale"

# Monitor for 5 minutes with detailed tracking
echo "\n🔍 Monitoring HPA scaling for 5 minutes..."
for i in {1..30}; do
    echo "\n=== Check $i/30 ($(date +%H:%M:%S)) ==="
    
    # Get HPA status
    HPA_STATUS=$(kubectl get hpa nginx-hpa --no-headers)
    echo "HPA: $HPA_STATUS"
    
    # Get current memory usage
    echo "Memory Usage:"
    kubectl top pods -l app=nginx 2>/dev/null || echo "  Metrics collecting..."
    
    # Check if scaling occurred
    CURRENT_REPLICAS=$(kubectl get deployment nginx-deployment -o jsonpath='{.status.replicas}')
    echo "Current Replicas: $CURRENT_REPLICAS"
    
    if [ "$CURRENT_REPLICAS" -gt 2 ]; then
        echo "🎉 SUCCESS! HPA has scaled up to $CURRENT_REPLICAS replicas!"
        echo "✅ HPA is working correctly!"
        break
    fi
    
    sleep 10
done

echo "\n📊 Final Status Check:"
kubectl get hpa nginx-hpa
kubectl get pods -l app=nginx
kubectl top pods -l app=nginx 2>/dev/null

echo "\n🧹 To stop the load test:"
echo "   kubectl delete pod --all --force --grace-period=0"
echo "   ./scripts/cleanup.sh"