#!/bin/bash
# Q14 — Select and Apply the Correct NetworkPolicy: Setup
set -e

echo "Creating namespaces..."
kubectl create namespace frontend --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace backend --dry-run=client -o yaml | kubectl apply -f -

echo "Labeling namespaces..."
kubectl label namespace frontend name=frontend --overwrite
kubectl label namespace backend name=backend --overwrite

echo "Deploying backend app..."
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend-deployment
  namespace: backend
spec:
  replicas: 1
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
      - name: backend
        image: nginx
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: backend-service
  namespace: backend
spec:
  selector:
    app: backend
  ports:
  - port: 80
    targetPort: 80
EOF

echo "Deploying frontend app..."
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend-deployment
  namespace: frontend
spec:
  replicas: 1
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: frontend
        image: curlimages/curl
        command: ["sleep", "3600"]
EOF

echo "Creating NetworkPolicy template files in /root/network-policies/..."
mkdir -p /root/network-policies

# Policy 1: Too permissive — allows ALL ingress to ALL pods
cat <<EOF > /root/network-policies/network-policy-1.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: policy-x
  namespace: backend
spec:
  podSelector: {}
  ingress:
  - {}
  policyTypes:
  - Ingress
EOF

# Policy 2: OR logic — allows frontend namespace OR frontend pods (too permissive)
cat <<EOF > /root/network-policies/network-policy-2.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: policy-y
  namespace: backend
spec:
  podSelector:
    matchLabels:
      app: backend
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: frontend
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - protocol: TCP
      port: 80
  policyTypes:
  - Ingress
EOF

# Policy 3: AND logic — allows ONLY frontend pods FROM frontend namespace (least permissive)
cat <<EOF > /root/network-policies/network-policy-3.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: policy-z
  namespace: backend
spec:
  podSelector:
    matchLabels:
      app: backend
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: frontend
      podSelector:
        matchLabels:
          app: frontend
    ports:
    - protocol: TCP
      port: 80
  policyTypes:
  - Ingress
EOF

echo ""
echo "Setup complete!"
echo "  - Namespaces: frontend, backend"
echo "  - Deployments: frontend-deployment, backend-deployment"
echo "  - Three policy files in /root/network-policies/"
echo ""
echo "Your tasks:"
echo "  1. Review all three NetworkPolicy files"
echo "  2. Identify which is the LEAST permissive"
echo "  3. Apply only the correct policy"
