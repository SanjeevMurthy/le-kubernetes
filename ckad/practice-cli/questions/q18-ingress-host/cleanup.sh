#!/bin/bash
# Q18 — Create Ingress with Host Rule: Cleanup
kubectl delete ingress webapp-ingress --ignore-not-found &>/dev/null || true
kubectl delete service webapp-svc --ignore-not-found &>/dev/null || true
kubectl delete deployment webapp --ignore-not-found &>/dev/null || true
echo "Cleanup complete"
