#!/bin/bash
# Q36 PSA violators: verify. The graded facts are the enforce label, an exact
# list of the two offending pods, and that enforcement is really live.
source "$(dirname "$0")/../../lib/checks.sh"
source "$(dirname "$0")/../../lib/env.sh"

NS=psa-lab
FILE="$COURSE_DIR/36/violators.txt"

echo "Checking the namespace label..."
check_eq "pod-security.kubernetes.io/enforce is baseline" "baseline" \
  "$(kjp namespace "$NS" "" '{.metadata.labels.pod-security\.kubernetes\.io/enforce}')"

echo "Checking the deliverable $FILE..."
check "violators.txt exists" test -f "$FILE"
# Whitespace and blank lines are forgiven; the set of names is not.
LIST=$(tr -d ' \t\r' < "$FILE" 2>/dev/null | grep -v '^$' | sort | tr '\n' ' ' | sed 's/ *$//')
check_eq "it lists exactly the two violators, sorted" "hostpid priv" "$LIST"

echo "Checking the three pods were left alone..."
for p in priv hostpid clean; do
  check_pod_running "pod $p is still Running" "$p" "$NS"
done

echo "Effect test: baseline is enforced on new pods..."
# Control case first. If admission rejected everything, or the namespace were
# gone, the privileged pod below would also fail and prove nothing.
check "a baseline-compliant pod is still admitted" \
  kubectl run psa-probe-ok -n "$NS" --image=busybox:1.36 --restart=Never \
  --dry-run=server -- sleep 1
check_not "a privileged pod is now rejected" \
  kubectl run psa-probe-bad -n "$NS" --image=busybox:1.36 --restart=Never \
  --dry-run=server \
  --overrides='{"spec":{"containers":[{"name":"psa-probe-bad","image":"busybox:1.36","securityContext":{"privileged":true}}]}}' \
  -- sleep 1

summary
