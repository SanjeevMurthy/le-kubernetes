#!/bin/bash
kubectl delete ingress echo -n echo-sound --ignore-not-found
kubectl delete svc echo-service -n echo-sound --ignore-not-found
kubectl delete ns echo-sound --ignore-not-found
echo "✅ Cleanup complete"
