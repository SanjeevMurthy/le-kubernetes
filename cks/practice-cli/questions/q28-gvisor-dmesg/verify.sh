#!/bin/bash
# Q28 gVisor dmesg: verify. A runtimeClassName in the spec proves intent, not
# effect, so the graded fact is the sandbox kernel banner in dmesg.
source "$(dirname "$0")/../../lib/checks.sh"
source "$(dirname "$0")/../../lib/env.sh"

NS=gvisor-lab
POD=gvisor-test
OUT="$COURSE_DIR/28/dmesg.txt"

echo "Checking the RuntimeClass..."
check_eq "RuntimeClass gvisor uses handler runsc" "runsc" "$(kjp runtimeclass gvisor '' '{.handler}')"

echo "Checking pod $POD in namespace $NS..."
check_eq "pod $POD sets runtimeClassName gvisor" "gvisor" "$(kjp pod "$POD" "$NS" '{.spec.runtimeClassName}')"
check_contains "pod $POD runs the requested image" "nginx" "$(kjp pod "$POD" "$NS" '{.spec.containers[*].image}')"
check_pod_running "pod $POD is Running" "$POD" "$NS"

echo "Reading the kernel ring buffer inside the pod (effect test)..."
# Precondition: exec has to work at all, otherwise the dmesg result below would
# be empty for a reason that has nothing to do with gVisor.
check "exec into $NS/$POD works" kubectl exec -n "$NS" "$POD" -- true
DMESG=$(kubectl exec -n "$NS" "$POD" -- dmesg 2>/dev/null | head -20)
if [[ -z "$DMESG" ]]; then
  echo "  FAIL: 'dmesg' produced no output in $NS/$POD (a host-kernel container is not allowed to read it)"; FAIL=$((FAIL + 1))
elif echo "$DMESG" | grep -qi 'gvisor'; then
  echo "  PASS: the live container reports the gVisor sandbox kernel"; PASS=$((PASS + 1))
else
  echo "  FAIL: dmesg shows a host kernel, not gVisor: $(echo "$DMESG" | head -1)"; FAIL=$((FAIL + 1))
fi

echo "Checking the deliverable..."
check "$OUT exists" test -s "$OUT"
if [[ -s "$OUT" ]]; then
  if grep -qi 'gvisor' "$OUT"; then
    echo "  PASS: $OUT was captured from inside the sandbox (it names gVisor)"; PASS=$((PASS + 1))
  else
    echo "  FAIL: $OUT does not mention gVisor; capture it with: kubectl exec -n $NS $POD -- dmesg > $OUT"; FAIL=$((FAIL + 1))
  fi
fi

summary
