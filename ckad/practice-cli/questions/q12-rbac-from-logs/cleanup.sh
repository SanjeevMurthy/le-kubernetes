#!/bin/bash
# Q12 — RBAC from Pod Logs: Cleanup
kubectl delete namespace audit --ignore-not-found &>/dev/null || true
echo "Cleanup complete"
