#!/bin/bash
# Q6 — HPA: Cleanup
kubectl delete hpa apache-server -n autoscale --ignore-not-found
kubectl delete svc apache-deployment -n autoscale --ignore-not-found
kubectl delete deployment apache-deployment -n autoscale --ignore-not-found
kubectl delete ns autoscale --ignore-not-found
echo "✅ Cleanup complete"
