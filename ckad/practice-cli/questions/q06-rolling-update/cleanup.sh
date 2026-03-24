#!/bin/bash
# Q6 — Rolling Update and Rollback: Cleanup
kubectl delete deployment app-v1 --ignore-not-found &>/dev/null || true
echo "Cleanup complete"
