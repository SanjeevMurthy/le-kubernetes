#!/bin/bash
# Q14 — Security Context Configuration: Cleanup
kubectl delete deployment secure-app --ignore-not-found &>/dev/null || true
echo "Cleanup complete"
