#!/bin/bash
# Q8 — Fix Pending Pods by Adjusting Resource Requests: Setup
set -e

echo "Creating WordPress deployment with oversized resources..."
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
        image: busybox:stable
        command: ["sh", "-c", "echo 'Preparing environment...' && sleep 2"]
        resources:
          requests:
            cpu: "2"
            memory: "3Gi"
          limits:
            cpu: "2"
            memory: "3Gi"
      containers:
      - name: wordpress
        image: wordpress:6.4
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: "2"
            memory: "3Gi"
          limits:
            cpu: "2"
            memory: "3Gi"
EOF

echo ""
echo "Waiting for scheduler to process..."
sleep 8

echo ""
echo "Current pod status:"
kubectl get pods -l app=wordpress -o wide

PENDING=$(kubectl get pods -l app=wordpress --no-headers 2>/dev/null | grep -c "Pending" || true)
if [[ "$PENDING" -gt 0 ]]; then
  echo ""
  echo "$PENDING pod(s) are Pending due to insufficient resources."
else
  echo ""
  echo "NOTE: All pods may be running if your cluster has enough resources."
  echo "The resource requests may need to be higher for your cluster."
fi

echo ""
echo "Your tasks:"
echo "  1. Scale the deployment to 0 replicas"
echo "  2. Calculate fair resources based on node capacity"
echo "  3. Set identical resources on init and main containers"
echo "  4. Scale back to 3 replicas — all must be Running"
