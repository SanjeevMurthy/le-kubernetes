#!/bin/bash
# Q7 — Create HPA with Downscale Stabilization: Setup
set -e

echo "Creating namespace: autoscale"
kubectl create namespace autoscale --dry-run=client -o yaml | kubectl apply -f -

echo "Deploying metrics-server (required for HPA)..."
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

echo "Patching metrics-server to allow insecure TLS (playground environment)..."
kubectl patch deployment metrics-server -n kube-system \
  --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]' 2>/dev/null || true

echo "Waiting for metrics-server rollout..."
kubectl rollout status deployment metrics-server -n kube-system --timeout=90s

echo "Creating Apache deployment with CPU resource requests..."
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: apache-deployment
  namespace: autoscale
spec:
  replicas: 1
  selector:
    matchLabels:
      app: apache
  template:
    metadata:
      labels:
        app: apache
    spec:
      containers:
      - name: apache
        image: httpd:2.4
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 200m
            memory: 256Mi
EOF

echo "Creating Apache service..."
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: apache-deployment
  namespace: autoscale
spec:
  selector:
    app: apache
  ports:
  - port: 80
    targetPort: 80
EOF

echo ""
echo "Setup complete!"
echo "  - Namespace: autoscale"
echo "  - Deployment: apache-deployment (with CPU requests)"
echo "  - Service: apache-deployment"
echo ""
echo "Your tasks:"
echo "  1. Create HPA named 'apache-server' targeting apache-deployment"
echo "  2. Set CPU target 50%, min=1, max=4"
echo "  3. Set downscale stabilization window to 30 seconds"
