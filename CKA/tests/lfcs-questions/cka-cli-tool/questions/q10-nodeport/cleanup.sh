#!/bin/bash
kubectl delete svc nodeport-service -n relative --ignore-not-found
kubectl delete deployment nodeport-deployment -n relative --ignore-not-found
kubectl delete ns relative --ignore-not-found
echo "✅ Cleanup complete"
