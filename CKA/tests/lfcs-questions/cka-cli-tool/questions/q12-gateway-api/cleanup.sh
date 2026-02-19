#!/bin/bash
kubectl delete httproute web-route --ignore-not-found
kubectl delete gateway web-gateway --ignore-not-found
echo "✅ Cleanup complete"
