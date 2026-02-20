#!/bin/bash
kubectl delete ns argocd --ignore-not-found
helm repo remove argocd 2>/dev/null || true
rm -f /root/argo-helm.yaml
echo "✅ Cleanup complete"
