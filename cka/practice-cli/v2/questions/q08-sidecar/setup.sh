#!/bin/bash
set -e
# Q8 — Add Sidecar Log Container: Setup

kubectl create namespace logging --dry-run=client -o yaml | kubectl apply -f - &>/dev/null

cat <<EOF | kubectl apply -f - &>/dev/null
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-deployment
  namespace: logging
spec:
  replicas: 1
  selector:
    matchLabels:
      app: app-deployment
  template:
    metadata:
      labels:
        app: app-deployment
    spec:
      containers:
      - name: main
        image: busybox:stable
        command: ["/bin/sh", "-c", "while true; do echo \$(date) app running >> /var/log/app.log; sleep 5; done"]
EOF
