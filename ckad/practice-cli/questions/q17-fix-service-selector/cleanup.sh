#!/bin/bash
# Q17 — Fix Service Selector Mismatch: Cleanup
kubectl delete service web-svc --ignore-not-found &>/dev/null || true
kubectl delete deployment web-app --ignore-not-found &>/dev/null || true
echo "Cleanup complete"
