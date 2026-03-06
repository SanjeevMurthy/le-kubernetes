#!/bin/bash
# Q18 — Create StorageClass and Set as Default: Cleanup
kubectl delete storageclass fast-storage --ignore-not-found &>/dev/null
echo "Cleanup complete"
