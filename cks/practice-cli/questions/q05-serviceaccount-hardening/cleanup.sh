#!/bin/bash
# Q5 — Cleanup
kubectl delete namespace app --ignore-not-found &>/dev/null
echo "Cleanup complete"
