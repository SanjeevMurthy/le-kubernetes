#!/bin/bash
set -e
# Q3 — Ingress TLS: Setup
kubectl create namespace prod 2>/dev/null || true
kubectl -n prod create deployment web --image=nginx 2>/dev/null || true
kubectl -n prod expose deployment web --port=80 --target-port=80 2>/dev/null || true
echo "Setup complete: namespace 'prod' with deployment+service 'web' on port 80."
echo "Create secret 'web-tls' (kubernetes.io/tls) and Ingress 'web-ingress' for host secure.example.com."
