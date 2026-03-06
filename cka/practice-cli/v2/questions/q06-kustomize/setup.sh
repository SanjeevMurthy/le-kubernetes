#!/bin/bash
set -e
# Q6 — Kustomize Deployment Tasks: Setup
# Create base directory structure and production namespace

# Clean prior state
rm -rf /root/kustomize-lab
kubectl delete ns production --ignore-not-found &>/dev/null

# Create base directory
mkdir -p /root/kustomize-lab/base

# Create base deployment
cat > /root/kustomize-lab/base/deployment.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
  labels:
    app: my-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - name: nginx
        image: nginx:1.24
        ports:
        - containerPort: 80
EOF

# Create base service
cat > /root/kustomize-lab/base/service.yaml <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: my-app
spec:
  type: ClusterIP
  selector:
    app: my-app
  ports:
  - port: 80
    targetPort: 80
EOF

# Create base kustomization
cat > /root/kustomize-lab/base/kustomization.yaml <<'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - deployment.yaml
  - service.yaml
EOF

# Create production namespace
kubectl create ns production --dry-run=client -o yaml | kubectl apply -f - &>/dev/null
