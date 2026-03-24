#!/bin/bash
# Q3 — Create Job from CronJob: Verify
PASS=0; FAIL=0

echo "Checking CronJob report-generator exists in analytics namespace..."
if kubectl get cronjob report-generator -n analytics &>/dev/null; then
  echo "  PASS: CronJob report-generator exists"
  ((PASS++))
else
  echo "  FAIL: CronJob report-generator not found in analytics namespace"
  ((FAIL++))
fi

echo "Checking a Job exists in analytics namespace created from report-generator..."
# Look for jobs with the cronjob annotation or name pattern
JOB_NAME=$(kubectl get jobs -n analytics -o jsonpath='{.items[*].metadata.name}' 2>/dev/null || echo "")
if [[ -n "$JOB_NAME" ]]; then
  echo "  PASS: Job(s) found in analytics namespace: $JOB_NAME"
  ((PASS++))
else
  echo "  FAIL: No jobs found in analytics namespace"
  ((FAIL++))
fi

echo "Checking Job references report-generator cronjob..."
FOUND_REF=false
for JOB in $JOB_NAME; do
  # Check for the manual instantiation annotation
  ANNOTATION=$(kubectl get job "$JOB" -n analytics -o jsonpath='{.metadata.annotations.cronjob\.kubernetes\.io/instantiate}' 2>/dev/null || echo "")
  # Check if job name starts with report-generator
  if [[ "$ANNOTATION" == "manual" ]] || [[ "$JOB" == report-generator-* ]]; then
    FOUND_REF=true
    break
  fi
done
if [[ "$FOUND_REF" == "true" ]]; then
  echo "  PASS: Job references report-generator cronjob"
  ((PASS++))
else
  echo "  FAIL: No job found referencing report-generator (jobs: $JOB_NAME)"
  ((FAIL++))
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
