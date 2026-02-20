#!/bin/bash
# Q15 — TLS Config: Cleanup
kubectl delete ns nginx-static --ignore-not-found
# Remove /etc/hosts entry (Linux sed syntax — no '' after -i)
sudo sed -i '/ckaquestion.k8s.local/d' /etc/hosts 2>/dev/null || true
echo "✅ Cleanup complete"
