#!/bin/bash
# Q2 — Create CronJob: Cleanup
kubectl delete cronjob backup-job --ignore-not-found &>/dev/null || true
kubectl delete job backup-job-test --ignore-not-found &>/dev/null || true
echo "Cleanup complete"
