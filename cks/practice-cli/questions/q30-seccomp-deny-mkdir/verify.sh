#!/bin/bash
# Q30 seccomp deny mkdir: verify.
source "$(dirname "$0")/../../lib/checks.sh"
source "$(dirname "$0")/../../lib/env.sh"

NS=seccomp-lab
POD=sandboxed
PROFILE=/var/lib/kubelet/seccomp/profiles/no-mkdir.json
OUT="$COURSE_DIR/30/result.txt"
W=$(worker_node)

echo "Checking the profile on worker ${W:-<none>}..."
check "$PROFILE exists on the worker" on_worker test -s "$PROFILE"
JSON=$(on_worker cat "$PROFILE" 2>/dev/null | tr -d ' \n\t')
check_contains "the profile allows everything by default" '"defaultAction":"SCMP_ACT_ALLOW"' "$JSON"
check_contains "a rule returns an error rather than killing the process" 'SCMP_ACT_ERRNO' "$JSON"
check_contains "the blocked syscall is mkdir" 'mkdir' "$JSON"

echo "Checking pod $POD in namespace $NS..."
t=$(kjp pod "$POD" "$NS" '{.spec.securityContext.seccompProfile.type}')
[[ -z "$t" ]] && t=$(kjp pod "$POD" "$NS" '{.spec.containers[0].securityContext.seccompProfile.type}')
check_eq "seccompProfile.type is Localhost" "Localhost" "$t"
p=$(kjp pod "$POD" "$NS" '{.spec.securityContext.seccompProfile.localhostProfile}')
[[ -z "$p" ]] && p=$(kjp pod "$POD" "$NS" '{.spec.containers[0].securityContext.seccompProfile.localhostProfile}')
check_eq "localhostProfile is profiles/no-mkdir.json" "profiles/no-mkdir.json" "$p"
check_pod_running "pod $POD is Running" "$POD" "$NS"

echo "Testing the filter inside the pod (effect test)..."
# Precondition first. `kubectl exec` fails when the pod is missing or not
# Running, which would make the denied mkdir below pass for the wrong reason.
# Prove that exec works and that ordinary work still succeeds, then test what
# has to fail.
check "exec into $NS/$POD works" kubectl exec -n "$NS" "$POD" -- true
check "an allowed syscall still works (writing a file)" \
  kubectl exec -n "$NS" "$POD" -- touch /tmp/verify-allowed
check_not "creating a directory is denied" \
  kubectl exec -n "$NS" "$POD" -- mkdir /tmp/verify-x
kubectl exec -n "$NS" "$POD" -- rm -f /tmp/verify-allowed >/dev/null 2>&1

echo "Checking the deliverable..."
check "$OUT exists" test -s "$OUT"
check_file_has "$OUT holds the error the blocked syscall produced" '[Nn]ot permitted' "$OUT"

summary
