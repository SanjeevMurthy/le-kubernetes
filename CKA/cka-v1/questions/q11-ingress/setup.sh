#!/bin/bash
# Q12 — Create an Ingress Resource: Setup
set -e

echo "Creating namespace: echo-sound"
kubectl create ns echo-sound --dry-run=client -o yaml | kubectl apply -f -

echo "Deploying echo-server in namespace echo-sound..."
cat <<EOF | kubectl -n echo-sound apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: echo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: echo
  template:
    metadata:
      labels:
        app: echo
    spec:
      containers:
      - name: echo
        image: gcr.io/google_containers/echoserver:1.10
        ports:
        - containerPort: 8080
EOF

echo ""
echo "Setup complete!"
echo "  - Namespace: echo-sound"
echo "  - Deployment: echo (listening on port 8080)"
echo ""
echo "Your tasks:"
echo "  1. Expose the deployment with service 'echo-service' (port 8080, NodePort)"
echo "  2. Create ingress 'echo' for http://example.org/echo"
