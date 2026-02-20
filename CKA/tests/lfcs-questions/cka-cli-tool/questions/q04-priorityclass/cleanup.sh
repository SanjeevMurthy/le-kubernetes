#!/bin/bash
# Q4 — PriorityClass: Cleanup
kubectl delete priorityclass high-priority --ignore-not-found
kubectl delete deployment busybox-logger -n priority --ignore-not-found
kubectl delete ns priority --ignore-not-found
echo "✅ Cleanup complete"
