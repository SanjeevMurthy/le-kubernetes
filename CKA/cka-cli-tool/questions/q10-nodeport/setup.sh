#!/bin/bash
# Q11 — Expose Deployment with NodePort: Setup
set -e

echo "Creating namespace: relative"
kubectl create namespace relative --dry-run=client -o yaml | kubectl apply -f -

echo "Creating deployment: nodeport-deployment (without named port)"
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nodeport-deployment
  namespace: relative
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nodeport-deployment
  template:
    metadata:
      labels:
        app: nodeport-deployment
    spec:
      containers:
      - name: nginx
        image: nginx
EOF

echo ""
echo "Setup complete!"
echo "  - Namespace: relative"
echo "  - Deployment: nodeport-deployment (2 replicas, no port definition)"
echo ""
echo "Your tasks:"
echo "  1. Configure the deployment with containerPort 80, name=http, protocol TCP"
echo "  2. Create service 'nodeport-service' with NodePort 30080"
