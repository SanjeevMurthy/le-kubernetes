#!/bin/bash
set -e

# Step 1: Create namespace
kubectl create namespace relative --dry-run=client -o yaml | kubectl apply -f -

# Step 2: Create deployment
kubectl apply -n relative -f - <<EOF
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
        ports:
        - containerPort: 80
EOF

# Step 3: Expose deployment via NodePort
echo "Deployment 'nodeport-deployment' created in namespace 'relative'."
echo "Task: expose it via NodePort using a Service."
