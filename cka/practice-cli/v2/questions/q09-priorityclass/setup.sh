#!/bin/bash
set -e
# Q9 — PriorityClass Creation and Assignment: Setup

kubectl create namespace production --dry-run=client -o yaml | kubectl apply -f - &>/dev/null

cat <<EOF | kubectl apply -f - &>/dev/null
apiVersion: apps/v1
kind: Deployment
metadata:
  name: critical-app
  namespace: production
spec:
  replicas: 1
  selector:
    matchLabels:
      app: critical-app
  template:
    metadata:
      labels:
        app: critical-app
    spec:
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
EOF
