#!/bin/bash
# Q10 — NodePort: Cleanup
kubectl delete svc nodeport-service --ignore-not-found
kubectl delete deployment nodeport-deployment --ignore-not-found
echo "✅ Cleanup complete"
