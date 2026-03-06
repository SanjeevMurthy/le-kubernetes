#!/bin/bash
# Q14 — Gateway API Migration with TLS: Cleanup
kubectl delete httproute web-route --ignore-not-found &>/dev/null
kubectl delete gateway web-gateway --ignore-not-found &>/dev/null
kubectl delete ingress web --ignore-not-found &>/dev/null
kubectl delete service web-service --ignore-not-found &>/dev/null
kubectl delete deployment web-deployment --ignore-not-found &>/dev/null
kubectl delete secret web-tls --ignore-not-found &>/dev/null
kubectl delete gatewayclass nginx-class --ignore-not-found &>/dev/null
echo "Cleanup complete"
