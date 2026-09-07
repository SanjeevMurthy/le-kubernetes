#!/bin/bash
# Q13 Trivy: verify.
source "$(dirname "$0")/../../lib/checks.sh"
source "$(dirname "$0")/../../lib/env.sh"

NS=trivy-lab
REPORT="$COURSE_DIR/13/report.txt"

IMG=$(kjp deploy web "$NS" '{.spec.template.spec.containers[0].image}')
echo "Current image: ${IMG:-<none>}"

echo "Checking the scan report deliverable..."
check "the report exists at $REPORT" test -s "$REPORT"
check_file_has "the report is a scan of nginx:1.18.0" 'nginx:1\.18\.0' "$REPORT"
check_file_has "the report contains CRITICAL findings" 'CRITICAL' "$REPORT"

echo "Checking the vulnerable image was replaced..."
if [[ "$IMG" == nginx:* && "$IMG" != "nginx:1.18.0" && "$IMG" != "nginx:latest" ]]; then
  echo "  PASS: image updated to $IMG"; PASS=$((PASS + 1))
else
  echo "  FAIL: image is '$IMG'; replace nginx:1.18.0 with a patched, pinned tag"; FAIL=$((FAIL + 1))
fi

echo "Checking the new image actually runs (effect test)..."
check "rollout of deploy/web completed" kubectl rollout status deploy/web -n "$NS" --timeout=60s
pod=$(kubectl get pod -n "$NS" -l app=web -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
check_pod_running "pod ${pod:-<missing>} is Running on the patched image" "$pod" "$NS"

summary
