#!/bin/bash
# Q18 — Create Ingress with Host Rule: Cleanup
kubectl delete ingress web-ingress --ignore-not-found &>/dev/null || true
kubectl delete service web-svc --ignore-not-found &>/dev/null || true
kubectl delete deployment web-deploy --ignore-not-found &>/dev/null || true
echo "Cleanup complete"
