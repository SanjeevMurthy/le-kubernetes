#!/bin/bash
# Q10 — Taints and Tolerations: Setup
# No specific setup needed — this question uses the playground cluster as-is.
# Requires a multi-node cluster with at least one worker node (node01).

echo "No additional setup needed for this question."
echo ""

if kubectl get node node01 &>/dev/null; then
  echo "  node01 found in cluster."
else
  echo "  WARNING: node01 not found. This question requires a multi-node cluster."
fi
echo ""
echo "Your tasks:"
echo "  1. Add taint to node01: PERMISSION=granted:NoSchedule"
echo "  2. Create a pod with the matching toleration that runs on node01"
