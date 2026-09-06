#!/bin/bash
# Q31 Falco hunt: verify. Naming the pod is half the answer; the other half is
# that only the offending workload was stopped.
source "$(dirname "$0")/../../lib/checks.sh"
source "$(dirname "$0")/../../lib/env.sh"

NS=falco-hunt
OUT="$COURSE_DIR/31/offender.txt"
W=$(worker_node)

echo "Checking the deliverable $OUT..."
check "$OUT exists and is not empty" test -s "$OUT"
LINES=$(grep -c . "$OUT" 2>/dev/null || echo 0)
check_eq "$OUT holds exactly one non-empty line" 1 "$LINES"

ANS=$(grep -m1 . "$OUT" 2>/dev/null | tr -d ' \t\r')
if [[ "$ANS" =~ ^falco-hunt/inventory(-[a-z0-9]+)*$ ]]; then
  echo "  PASS: the offender is named as '$ANS'"; PASS=$((PASS + 1))
else
  echo "  FAIL: expected the noisy pod as 'falco-hunt/<pod-name>', got '${ANS:-<empty>}'"; FAIL=$((FAIL + 1))
fi

echo "Checking the offending workload was scaled down..."
check_eq "deployment inventory is scaled to 0 replicas" 0 "$(kjp deploy inventory "$NS" '{.spec.replicas}')"
RUNNING=$(kubectl get pods -n "$NS" -l app=inventory --field-selector=status.phase=Running -o name 2>/dev/null | grep -c . || echo 0)
check_eq "no inventory pod is running any more" 0 "$RUNNING"

echo "Checking the innocent workload was left alone..."
check_eq "deployment catalog still asks for 1 replica" 1 "$(kjp deploy catalog "$NS" '{.spec.replicas}')"
check_eq "deployment catalog still has 1 ready replica" 1 "$(kjp deploy catalog "$NS" '{.status.readyReplicas}')"
CPOD=$(kubectl get pod -n "$NS" -l app=catalog -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
check_pod_running "the catalog pod ${CPOD:-<missing>} is still Running" "$CPOD" "$NS"

echo "Checking Falco is still watching on ${W:-the worker}..."
if on_worker systemctl is-active --quiet falco-modern-bpf 2>/dev/null || on_worker systemctl is-active --quiet falco 2>/dev/null; then
  echo "  PASS: the Falco service is still active"; PASS=$((PASS + 1))
else
  echo "  FAIL: neither falco-modern-bpf nor falco is active; the detector must stay up"; FAIL=$((FAIL + 1))
fi

summary
