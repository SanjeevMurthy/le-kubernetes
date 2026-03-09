#!/bin/bash
# Q24 — CrashLoopBackOff Debug: Cleanup
kubectl delete namespace debug-ns --ignore-not-found &>/dev/null || true
rm -f /root/crash-events.txt || true
echo "Cleanup complete"
