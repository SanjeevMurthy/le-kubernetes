#!/bin/bash
# Q5 — Canary Deployment: Cleanup
kubectl delete deployment web-app --ignore-not-found &>/dev/null || true
kubectl delete deployment web-app-canary --ignore-not-found &>/dev/null || true
kubectl delete svc web-app-svc --ignore-not-found &>/dev/null || true
echo "Cleanup complete"
