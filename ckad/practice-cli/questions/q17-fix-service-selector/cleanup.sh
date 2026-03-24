#!/bin/bash
# Q17 — Fix Service Selector Mismatch: Cleanup
kubectl delete service backend-svc --ignore-not-found &>/dev/null || true
kubectl delete deployment backend --ignore-not-found &>/dev/null || true
echo "Cleanup complete"
