#!/bin/bash
# Q34 AppArmor name trap: verify. The graded facts are the loaded profile name,
# the name the pod asks for, and a write that is actually refused.
source "$(dirname "$0")/../../lib/checks.sh"
source "$(dirname "$0")/../../lib/env.sh"

NS=apparmor-trap
POD=guarded
PROFILE_FILE=/etc/apparmor.d/k8s-lab-deny-write
W=$(worker_node)

TMP=$(mktemp)
on_worker cat "$PROFILE_FILE" > "$TMP" 2>/dev/null || true

echo "Checking the profile file on ${W:-the worker} was left alone..."
check "$PROFILE_FILE still exists and was read" test -s "$TMP"
check_file_has "it still declares the profile deny-write-lab" '^ *profile +deny-write-lab' "$TMP"

echo "Checking the profile is loaded in enforce mode..."
ENFORCED=$(on_worker aa-status 2>/dev/null | sed -n '/enforce mode/,/complain mode/p' | grep -c 'deny-write-lab')
if [[ "${ENFORCED:-0}" -ge 1 ]]; then
  echo "  PASS: deny-write-lab is loaded in enforce mode on ${W:-the worker}"; PASS=$((PASS + 1))
else
  echo "  FAIL: deny-write-lab is not in enforce mode; load it with apparmor_parser -q $PROFILE_FILE"; FAIL=$((FAIL + 1))
fi

echo "Checking pod $POD in namespace $NS..."
PROF=$(kjp pod "$POD" "$NS" '{.spec.containers[0].securityContext.appArmorProfile.localhostProfile}')
[[ -z "$PROF" ]] && PROF=$(kjp pod "$POD" "$NS" '{.spec.securityContext.appArmorProfile.localhostProfile}')
[[ -z "$PROF" ]] && PROF=$(kjp pod "$POD" "$NS" '{.metadata.annotations.container\.apparmor\.security\.beta\.kubernetes\.io/guarded}' | sed 's|^localhost/||')
check_eq "the pod asks for the profile name, not the file name" "deny-write-lab" "$PROF"
check_pod_running "pod $POD is Running" "$POD" "$NS"

echo "Checking the confinement is real (effect test)..."
# Control first. Without it, a pod that never started would make the denied
# write below look like a success.
check "exec works and /root is readable inside the container" kubectl exec -n "$NS" "$POD" -- ls /root
check_not "a write to /root is denied by AppArmor" kubectl exec -n "$NS" "$POD" -- touch /root/x

rm -f "$TMP"
summary
