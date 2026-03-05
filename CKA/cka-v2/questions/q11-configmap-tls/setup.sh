#!/bin/bash
set -e
# Q11 — NGINX ConfigMap TLS Configuration: Setup

kubectl create namespace nginx-tls --dry-run=client -o yaml | kubectl apply -f - &>/dev/null

# Generate self-signed TLS certificate
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /tmp/tls.key -out /tmp/tls.crt -subj "/CN=nginx-tls.k8s.local" 2>/dev/null

# Create TLS secret
kubectl -n nginx-tls create secret tls nginx-tls-secret \
  --cert=/tmp/tls.crt --key=/tmp/tls.key \
  --dry-run=client -o yaml | kubectl apply -f - &>/dev/null
rm -f /tmp/tls.crt /tmp/tls.key

# Create ConfigMap with TLSv1.3 only (task is to add TLSv1.2)
cat <<EOF | kubectl -n nginx-tls apply -f - &>/dev/null
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-config
data:
  nginx.conf: |
    events {}
    http {
      server {
        listen 443 ssl;
        ssl_certificate /etc/nginx/tls/tls.crt;
        ssl_certificate_key /etc/nginx/tls/tls.key;
        ssl_protocols TLSv1.3;
        location / {
          return 200 "Hello TLS\n";
        }
      }
    }
EOF

# Deploy nginx with ConfigMap and TLS mounts
cat <<EOF | kubectl -n nginx-tls apply -f - &>/dev/null
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-tls
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx-tls
  template:
    metadata:
      labels:
        app: nginx-tls
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 443
        volumeMounts:
        - name: config
          mountPath: /etc/nginx/nginx.conf
          subPath: nginx.conf
        - name: tls
          mountPath: /etc/nginx/tls
      volumes:
      - name: config
        configMap:
          name: nginx-config
      - name: tls
        secret:
          secretName: nginx-tls-secret
EOF

# Create ClusterIP service
cat <<EOF | kubectl -n nginx-tls apply -f - &>/dev/null
apiVersion: v1
kind: Service
metadata:
  name: nginx-tls-service
spec:
  selector:
    app: nginx-tls
  ports:
  - port: 443
    targetPort: 443
EOF
