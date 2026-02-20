#!/bin/bash
# Q13 — Gateway API: Cleanup
kubectl delete httproute web-route --ignore-not-found
kubectl delete gateway web-gateway --ignore-not-found
kubectl delete ingress web --ignore-not-found
kubectl delete svc web-service --ignore-not-found
kubectl delete deployment web-deployment --ignore-not-found
kubectl delete secret web-tls --ignore-not-found
kubectl delete gatewayclass nginx-class --ignore-not-found
echo "✅ Cleanup complete"
