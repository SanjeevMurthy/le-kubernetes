#!/bin/bash
# Q12 gVisor: verify.
source "$(dirname "$0")/../../lib/checks.sh"; source "$(dirname "$0")/../../lib/env.sh"
echo "Checking the RuntimeClass..."
check_eq "RuntimeClass gvisor uses handler runsc" "runsc" "$(kjp runtimeclass gvisor '' '{.handler}')"
echo "Checking pod sandboxed in namespace gvisor-lab..."
check_eq "pod sandboxed sets runtimeClassName gvisor" "gvisor" "$(kjp pod sandboxed gvisor-lab '{.spec.runtimeClassName}')"
check_pod_running "pod sandboxed is Running" sandboxed gvisor-lab
echo "Reading the kernel ring buffer inside the pod (effect test)..."
DMESG=$(kubectl exec -n gvisor-lab sandboxed -- dmesg 2>/dev/null | head -20)
if echo "$DMESG" | grep -qi 'gvisor'; then
  echo "  PASS: the container runs on the gVisor sandbox kernel"; PASS=$((PASS + 1))
elif [[ -z "$DMESG" ]]; then
  echo "  FAIL: could not run 'dmesg' in gvisor-lab/sandboxed (is the pod up and does the image have dmesg?)"; FAIL=$((FAIL + 1))
else
  echo "  FAIL: dmesg shows a host kernel, not gVisor: $(echo "$DMESG" | head -1)"; FAIL=$((FAIL + 1))
fi
summary
