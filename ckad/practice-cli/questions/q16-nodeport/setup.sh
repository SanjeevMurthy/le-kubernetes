#!/bin/bash
set -e
# Q16 — Create NodePort Service: Setup
#
# Uses busybox httpd to serve on port 9090 (not nginx, which only listens on 80).
# This ensures the Service targetPort 9090 actually reaches a listening process.

# Clean prior state
kubectl delete deployment api-server &>/dev/null || true

# Create deployment with container actually listening on port 9090
kubectl apply -f - &>/dev/null <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-server
  labels:
    app: api
spec:
  replicas: 2
  selector:
    matchLabels:
      app: api
  template:
    metadata:
      labels:
        app: api
    spec:
      containers:
      - name: api
        image: busybox:1.36
        command: ["sh", "-c", "mkdir -p /var/www && echo '<html><body><h1>API Server Running on port 9090</h1></body></html>' > /var/www/index.html && httpd -f -p 9090 -h /var/www"]
        ports:
        - containerPort: 9090
EOF

kubectl rollout status deployment api-server --timeout=60s &>/dev/null || true
