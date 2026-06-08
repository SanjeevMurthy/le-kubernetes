#!/bin/bash
set -e
# Q9 — Pod Security Admission: Setup
kubectl create namespace payments 2>/dev/null || true
echo "Setup complete: namespace 'payments'. Enforce the 'restricted' Pod Security Standard on it."
