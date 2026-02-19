#!/bin/bash
kubectl delete ns nginx-static --ignore-not-found
sudo sed -i '' '/ckaquestion.k8s.local/d' /etc/hosts 2>/dev/null || true
echo "✅ Cleanup complete"
