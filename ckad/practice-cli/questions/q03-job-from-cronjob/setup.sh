#!/bin/bash
set -e
# Q3 — Create Job from CronJob: Setup

# Clean prior state
kubectl delete namespace analytics --ignore-not-found &>/dev/null || true
kubectl wait --for=delete namespace/analytics --timeout=60s &>/dev/null || true
while kubectl get namespace analytics &>/dev/null 2>&1; do sleep 1; done

# Create namespace
kubectl create namespace analytics &>/dev/null

# Create CronJob report-generator in analytics namespace
cat <<EOF | kubectl apply -f - &>/dev/null
apiVersion: batch/v1
kind: CronJob
metadata:
  name: report-generator
  namespace: analytics
spec:
  schedule: "0 * * * *"
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: report
            image: busybox
            command: ["sh", "-c", "echo 'Generating report'"]
          restartPolicy: OnFailure
EOF

echo "Setup complete. CronJob report-generator created in analytics namespace."
