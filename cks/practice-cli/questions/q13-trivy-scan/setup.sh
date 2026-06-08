#!/bin/bash
set -e
# Q13 — Trivy scan + remediate: Setup
kubectl create namespace prod 2>/dev/null || true
kubectl -n prod create deployment web --image=nginx:1.18.0 2>/dev/null || true
echo "Setup complete: deployment 'web' in 'prod' runs nginx:1.18.0 (vulnerable)."
echo "Scan with trivy, then update 'web' to a patched image (e.g. nginx:1.27.0)."
