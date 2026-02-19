#!/bin/bash
# setup-wordpress.sh
# Create a WordPress deployment with 3 replicas, init container, and
# intentionally oversized resource requests so pods go Pending.
# The student must scale to 0, divide resources fairly, then scale back to 3.

set -e

echo "🔹 Creating WordPress deployment with oversized resources..."
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: wordpress
spec:
  replicas: 3
  selector:
    matchLabels:
      app: wordpress
  template:
    metadata:
      labels:
        app: wordpress
    spec:
      initContainers:
      - name: init-setup
        image: busybox
        command: ["sh", "-c", "echo 'Preparing environment...' && sleep 2"]
        resources:
          requests:
            cpu: "800m"
            memory: "1Gi"
          limits:
            cpu: "800m"
            memory: "1Gi"
      containers:
      - name: wordpress
        image: wordpress:6.2-apache
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: "800m"
            memory: "1Gi"
          limits:
            cpu: "800m"
            memory: "1Gi"
EOF

echo ""
echo "🔹 Waiting a few seconds for scheduler to process..."
sleep 5

echo ""
echo "🔹 Current pod status:"
kubectl get pods -l app=wordpress -o wide

PENDING=$(kubectl get pods -l app=wordpress --no-headers 2>/dev/null | grep -c Pending || echo "0")
echo ""
if [[ "$PENDING" -gt 0 ]]; then
  echo "✅ Lab setup complete! $PENDING pod(s) are Pending due to insufficient resources."
else
  echo "⚠️  All pods are running. The resource requests may need to be higher for your cluster."
  echo "   Check: kubectl describe pod <pending-pod> | grep -A5 Events"
fi
echo "   Task: Scale to 0, fix resources, scale back to 3 replicas — all Running."
