#!/bin/bash
# Q3 — Create Job from CronJob: Cleanup
kubectl delete namespace analytics --ignore-not-found &>/dev/null || true
echo "Cleanup complete"
