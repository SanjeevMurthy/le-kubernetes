#!/bin/bash
# Q43 strace: verify. Naming the pod is half the answer; the other half is that
# only the offending workload was removed, so wiping the namespace fails here.
source "$(dirname "$0")/../../lib/checks.sh"
source "$(dirname "$0")/../../lib/env.sh"

NS=strace-lab
OUT="$COURSE_DIR/43/pod.txt"

echo "Checking the lab is still there..."
# Precondition for everything below. "worker-a is gone" is also true when the
# whole namespace is gone, which would be a PASS for the wrong reason.
check "namespace $NS still exists" kubectl get namespace "$NS"

echo "Checking the innocent workload was left alone..."
check "deployment worker-b still exists" kubectl -n "$NS" get deploy worker-b
check_eq "deployment worker-b still asks for 1 replica" 1 "$(kjp deploy worker-b "$NS" '{.spec.replicas}')"
check_eq "deployment worker-b still has 1 ready replica" 1 "$(kjp deploy worker-b "$NS" '{.status.readyReplicas}')"
BPOD=$(kubectl get pod -n "$NS" -l app=worker-b -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
check_pod_running "the worker-b pod ${BPOD:-<missing>} is still Running" "$BPOD" "$NS"

echo "Checking the offending workload is gone..."
check_not "deployment worker-a has been deleted" kubectl -n "$NS" get deploy worker-a
APODS=$(kubectl get pod -n "$NS" -l app=worker-a -o name 2>/dev/null | grep -c .)
check_eq "no worker-a pod is left in $NS" 0 "${APODS:-0}"

echo "Checking the deliverable $OUT..."
check "$OUT exists and is not empty" test -s "$OUT"
# grep -c prints its count and exits 1 when the count is zero, so take the
# number it printed and never append a second one with `|| echo 0`.
LINES=$(grep -c . "$OUT" 2>/dev/null)
check_eq "$OUT holds exactly one non-empty line" 1 "${LINES:-0}"
ANS=$(grep -m1 . "$OUT" 2>/dev/null | tr -d ' \t\r')
if [[ "$ANS" =~ ^strace-lab/worker-a(-[a-z0-9]+)*$ ]]; then
  echo "  PASS: the caller is named as '$ANS'"; PASS=$((PASS + 1))
else
  echo "  FAIL: expected the noisy pod as 'strace-lab/<pod-name>', got '${ANS:-<empty>}'"; FAIL=$((FAIL + 1))
fi

summary
