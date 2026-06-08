#!/bin/bash
set -e
# Q5 — ServiceAccount token hardening: Setup
kubectl create namespace app 2>/dev/null || true
echo "Setup complete: namespace 'app'."
echo "Create SA 'app-sa' with automount disabled, and pod 'legacy' using it with no token mounted."
