#!/bin/bash
# Q19 — Create PVC and Bind to Existing PV: Cleanup
kubectl delete pod data-pod --ignore-not-found &>/dev/null
kubectl delete pvc data-pvc --ignore-not-found &>/dev/null
kubectl delete pv data-pv --ignore-not-found &>/dev/null
kubectl delete storageclass fast-storage --ignore-not-found &>/dev/null
echo "Cleanup complete"
