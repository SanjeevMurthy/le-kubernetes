#!/bin/bash
# Q2 — Create CronJob: Verify
PASS=0; FAIL=0

echo "Checking CronJob backup-job exists..."
if kubectl get cronjob backup-job &>/dev/null; then
  echo "  PASS: CronJob backup-job exists"
  ((PASS++))
else
  echo "  FAIL: CronJob backup-job not found"
  ((FAIL++))
fi

echo "Checking schedule is */30 * * * *..."
SCHEDULE=$(kubectl get cronjob backup-job -o jsonpath='{.spec.schedule}' 2>/dev/null || echo "")
if [[ "$SCHEDULE" == "*/30 * * * *" ]]; then
  echo "  PASS: Schedule is '*/30 * * * *'"
  ((PASS++))
else
  echo "  FAIL: Schedule is '$SCHEDULE' (expected: '*/30 * * * *')"
  ((FAIL++))
fi

echo "Checking successfulJobsHistoryLimit is 3..."
SUCCESS_LIMIT=$(kubectl get cronjob backup-job -o jsonpath='{.spec.successfulJobsHistoryLimit}' 2>/dev/null || echo "")
if [[ "$SUCCESS_LIMIT" == "3" ]]; then
  echo "  PASS: successfulJobsHistoryLimit is 3"
  ((PASS++))
else
  echo "  FAIL: successfulJobsHistoryLimit is '$SUCCESS_LIMIT' (expected: 3)"
  ((FAIL++))
fi

echo "Checking failedJobsHistoryLimit is 2..."
FAILED_LIMIT=$(kubectl get cronjob backup-job -o jsonpath='{.spec.failedJobsHistoryLimit}' 2>/dev/null || echo "")
if [[ "$FAILED_LIMIT" == "2" ]]; then
  echo "  PASS: failedJobsHistoryLimit is 2"
  ((PASS++))
else
  echo "  FAIL: failedJobsHistoryLimit is '$FAILED_LIMIT' (expected: 2)"
  ((FAIL++))
fi

echo "Checking activeDeadlineSeconds is 300..."
DEADLINE=$(kubectl get cronjob backup-job -o jsonpath='{.spec.jobTemplate.spec.activeDeadlineSeconds}' 2>/dev/null || echo "")
if [[ "$DEADLINE" == "300" ]]; then
  echo "  PASS: activeDeadlineSeconds is 300"
  ((PASS++))
else
  echo "  FAIL: activeDeadlineSeconds is '$DEADLINE' (expected: 300)"
  ((FAIL++))
fi

echo "Checking restartPolicy is Never..."
RESTART=$(kubectl get cronjob backup-job -o jsonpath='{.spec.jobTemplate.spec.template.spec.restartPolicy}' 2>/dev/null || echo "")
if [[ "$RESTART" == "Never" ]]; then
  echo "  PASS: restartPolicy is Never"
  ((PASS++))
else
  echo "  FAIL: restartPolicy is '$RESTART' (expected: Never)"
  ((FAIL++))
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
