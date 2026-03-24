#!/bin/bash
# Q24 — CrashLoopBackOff Debug: Cleanup
kubectl delete namespace debug-ns --ignore-not-found &>/dev/null || true
rm -f /root/error_events.txt || true
echo "Cleanup complete"
