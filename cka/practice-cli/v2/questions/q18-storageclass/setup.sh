#!/bin/bash
set -e
# Q18 — Create StorageClass and Set as Default: Setup

# List existing storage classes for reference
kubectl get storageclass &>/dev/null || true
