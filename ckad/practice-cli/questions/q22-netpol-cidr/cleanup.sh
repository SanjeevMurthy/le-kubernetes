#!/bin/bash
# Q22 — NetworkPolicy CIDR Egress: Cleanup
kubectl delete namespace cidr-ns --ignore-not-found &>/dev/null || true
echo "Cleanup complete"
