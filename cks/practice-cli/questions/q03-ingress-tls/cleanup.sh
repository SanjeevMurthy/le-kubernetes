#!/bin/bash
# Q3 — Cleanup
kubectl delete namespace prod --ignore-not-found &>/dev/null
echo "Cleanup complete"
