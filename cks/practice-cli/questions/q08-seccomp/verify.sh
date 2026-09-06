#!/bin/bash
# Q8 seccomp: both pods must declare the right profile AND the kernel must
# actually have a seccomp filter loaded for the audited container.
source "$(dirname "$0")/../../lib/checks.sh"; source "$(dirname "$0")/../../lib/env.sh"
NS=seccomp-lab
W=$(worker_node)

echo "Checking pod audited references the custom profile..."
t=$(kjp pod audited "$NS" '{.spec.securityContext.seccompProfile.type}')
[[ -z "$t" ]] && t=$(kjp pod audited "$NS" '{.spec.containers[0].securityContext.seccompProfile.type}')
check_eq "pod audited seccompProfile.type is Localhost" "Localhost" "$t"
p=$(kjp pod audited "$NS" '{.spec.securityContext.seccompProfile.localhostProfile}')
[[ -z "$p" ]] && p=$(kjp pod audited "$NS" '{.spec.containers[0].securityContext.seccompProfile.localhostProfile}')
check_eq "pod audited localhostProfile is profiles/audit.json" "profiles/audit.json" "$p"

echo "Checking pod default-seccomp uses RuntimeDefault..."
d=$(kjp pod default-seccomp "$NS" '{.spec.securityContext.seccompProfile.type}')
[[ -z "$d" ]] && d=$(kjp pod default-seccomp "$NS" '{.spec.containers[0].securityContext.seccompProfile.type}')
check_eq "pod default-seccomp seccompProfile.type is RuntimeDefault" "RuntimeDefault" "$d"

check_pod_running "pod audited is Running" audited "$NS"
check_pod_running "pod default-seccomp is Running" default-seccomp "$NS"
check "custom profile still present on worker $W" on_worker test -f /var/lib/kubelet/seccomp/profiles/audit.json

echo "Checking the kernel loaded a seccomp filter for audited (effect test)..."
cid=$(on_worker crictl pods -q --name audited --namespace "$NS" 2>/dev/null | head -1)
[[ -n "$cid" ]] && cid=$(on_worker crictl ps -q --pod "$cid" 2>/dev/null | head -1)
[[ -z "$cid" ]] && cid=$(on_worker crictl ps -q --name audited 2>/dev/null | head -1)
pid=""
[[ -n "$cid" ]] && pid=$(on_worker crictl inspect --output go-template --template '{{.info.pid}}' "$cid" 2>/dev/null)
mode=""
[[ -n "$pid" ]] && mode=$(on_worker cat "/proc/$pid/status" 2>/dev/null | awk '/^Seccomp:/ {print $2}')
if [[ "$mode" == "2" ]]; then
  echo "  PASS: /proc/$pid/status reports Seccomp: 2 (filter mode)"; PASS=$((PASS + 1))
elif [[ -z "$cid" ]]; then
  echo "  FAIL: no running container found for pod audited on $W"; FAIL=$((FAIL + 1))
else
  echo "  FAIL: expected Seccomp: 2 in /proc/$pid/status, got '$mode'"; FAIL=$((FAIL + 1))
fi

summary
