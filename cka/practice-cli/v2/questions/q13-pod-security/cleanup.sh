#!/bin/bash
# Q13 — Enforce Pod Security Standards: Cleanup
kubectl delete pod test-privileged -n secure-ns --ignore-not-found &>/dev/null
kubectl delete pod test-compliant -n secure-ns --ignore-not-found &>/dev/null
kubectl delete namespace secure-ns --ignore-not-found &>/dev/null
