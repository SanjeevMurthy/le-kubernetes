#!/bin/bash
set -e
# Q7 — Fix Deprecated API Version: Setup

# Clean prior state
kubectl delete deployment broken-app &>/dev/null || true
rm -f /root/broken-deploy.yaml &>/dev/null || true

# Create a broken deployment manifest with deprecated API version
cat > /root/broken-deploy.yaml <<'EOF'
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: broken-app
spec:
  replicas: 2
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
EOF

echo "Setup complete. Broken manifest created at /root/broken-deploy.yaml"
