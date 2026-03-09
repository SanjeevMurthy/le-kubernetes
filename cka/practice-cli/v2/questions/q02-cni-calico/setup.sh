#!/bin/bash
set -e
# Q2 — CNI Installation and Configuration - Calico: Setup
# Check current CNI state. This scenario requires a cluster without CNI installed.
# If CNI is already present, the setup notes this for the user.

# Check if calico is already running
if kubectl get pods -A 2>/dev/null | grep -q "calico"; then
  echo "NOTE: Calico CNI appears to already be installed on this cluster."
  echo "To fully practice this question, you need a cluster without CNI configured."
  exit 0
fi

# Check if any other CNI is running
if kubectl get pods -n kube-system 2>/dev/null | grep -qE "flannel|weave|cilium"; then
  echo "NOTE: A CNI plugin appears to already be installed on this cluster."
  echo "To fully practice this question, you need a cluster without CNI configured."
  exit 0
fi
