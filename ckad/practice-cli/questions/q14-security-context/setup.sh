#!/bin/bash
set -e
# Q14 — Security Context Configuration: Setup

# Clean prior state
kubectl delete deployment secure-app &>/dev/null || true
