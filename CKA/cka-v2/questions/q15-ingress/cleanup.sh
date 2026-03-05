#!/bin/bash
# Q15 — Create an Ingress Resource: Cleanup
kubectl delete ingress app-ingress -n echo-app --ignore-not-found &>/dev/null
kubectl delete service api-service -n echo-app --ignore-not-found &>/dev/null
kubectl delete deployment api-server -n echo-app --ignore-not-found &>/dev/null
kubectl delete namespace echo-app --ignore-not-found &>/dev/null
echo "Cleanup complete"
