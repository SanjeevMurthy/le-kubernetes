#!/bin/bash
# Q3 — CRD Tasks - List, Query, Manage CRDs: Cleanup
rm -f /root/resources.yaml
kubectl delete -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.0/cert-manager.crds.yaml &>/dev/null || true
kubectl delete ns cert-manager --ignore-not-found &>/dev/null
echo "Cleanup complete"
