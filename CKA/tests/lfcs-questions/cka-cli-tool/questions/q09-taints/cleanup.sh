#!/bin/bash
# Q9 — Taints: Cleanup
kubectl taint nodes node01 PERMISSION=granted:NoSchedule- 2>/dev/null || true
kubectl delete pod nginx --ignore-not-found
kubectl delete pod nginx-fail --ignore-not-found 2>/dev/null || true
echo "✅ Cleanup complete"
