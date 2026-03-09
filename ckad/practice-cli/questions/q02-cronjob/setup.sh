#!/bin/bash
set -e
# Q2 — Create CronJob: Setup

# Clean prior state
kubectl delete cronjob backup-job --ignore-not-found &>/dev/null || true
kubectl delete job backup-job-test --ignore-not-found &>/dev/null || true

echo "Setup complete. No pre-existing resources needed."
