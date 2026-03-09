#!/bin/bash
set -e
# Q10 — Resource Requests/Limits for Pending Pods: Setup

cat <<EOF | kubectl apply -f - &>/dev/null
apiVersion: apps/v1
kind: Deployment
metadata:
  name: resource-app
  namespace: default
spec:
  replicas: 3
  selector:
    matchLabels:
      app: resource-app
  template:
    metadata:
      labels:
        app: resource-app
    spec:
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: "2"
            memory: 3Gi
          limits:
            cpu: "2"
            memory: 3Gi
EOF
