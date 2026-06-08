#!/bin/bash
# Q2 — Verify (control-plane node)
PASS=0; FAIL=0
KAS=/etc/kubernetes/manifests/kube-apiserver.yaml
KUBELET=/var/lib/kubelet/config.yaml

echo "Checking apiserver --anonymous-auth=false..."
if [ -f "$KAS" ] && grep -q -- '--anonymous-auth=false' "$KAS"; then
  echo "  PASS: anonymous-auth disabled"; ((PASS++))
elif [ ! -f "$KAS" ]; then
  echo "  FAIL: $KAS not found — run on the control-plane node"; ((FAIL++))
else
  echo "  FAIL: --anonymous-auth=false not set in apiserver manifest"; ((FAIL++))
fi

echo "Checking kubelet readOnlyPort: 0..."
if [ -f "$KUBELET" ] && grep -Eq 'readOnlyPort:[[:space:]]*0' "$KUBELET"; then
  echo "  PASS: kubelet read-only port disabled"; ((PASS++))
elif [ ! -f "$KUBELET" ]; then
  echo "  FAIL: $KUBELET not found — run on the node"; ((FAIL++))
else
  echo "  FAIL: readOnlyPort: 0 not set in kubelet config"; ((FAIL++))
fi

echo ""; echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
