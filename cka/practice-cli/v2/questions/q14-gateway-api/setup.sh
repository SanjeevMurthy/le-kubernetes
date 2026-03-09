#!/bin/bash
set -e
# Q14 — Gateway API Migration with TLS: Setup

# Install Gateway API CRDs
kubectl apply -k "github.com/kubernetes-sigs/gateway-api/config/crd?ref=v1.1.0" &>/dev/null

# Create web deployment
kubectl create deployment web-deployment --image=nginx --replicas=2 &>/dev/null

# Create web service
kubectl expose deployment web-deployment --name=web-service --port=80 --target-port=80 &>/dev/null

# Generate TLS certificate and create secret
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /tmp/web-tls.key -out /tmp/web-tls.crt \
  -subj "/CN=gateway.web.k8s.local" &>/dev/null
kubectl create secret tls web-tls --cert=/tmp/web-tls.crt --key=/tmp/web-tls.key &>/dev/null
rm -f /tmp/web-tls.key /tmp/web-tls.crt

# Create existing Ingress with TLS
kubectl apply -f - &>/dev/null <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web
spec:
  tls:
  - hosts:
    - gateway.web.k8s.local
    secretName: web-tls
  rules:
  - host: gateway.web.k8s.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web-service
            port:
              number: 80
EOF

# Create GatewayClass
kubectl apply -f - &>/dev/null <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: nginx-class
spec:
  controllerName: example.com/nginx-gateway
EOF
