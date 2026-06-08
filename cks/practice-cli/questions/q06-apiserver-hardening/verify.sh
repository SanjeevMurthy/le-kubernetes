#!/bin/bash
# Q6 — Verify (control-plane node)
PASS=0; FAIL=0
KAS=/etc/kubernetes/manifests/kube-apiserver.yaml
if [ ! -f "$KAS" ]; then echo "  FAIL: $KAS not found — run on the control-plane node"; echo "Results: 0 passed, 1 failed"; exit 1; fi

echo "Checking --anonymous-auth=false..."
if grep -q -- '--anonymous-auth=false' "$KAS"; then echo "  PASS"; ((PASS++)); else echo "  FAIL: anonymous-auth not disabled"; ((FAIL++)); fi

echo "Checking authorization-mode includes Node and RBAC..."
if grep -- '--authorization-mode=' "$KAS" | grep -q 'Node' && grep -- '--authorization-mode=' "$KAS" | grep -q 'RBAC'; then echo "  PASS"; ((PASS++)); else echo "  FAIL: authorization-mode must be Node,RBAC"; ((FAIL++)); fi

echo "Checking enable-admission-plugins includes NodeRestriction..."
if grep -- '--enable-admission-plugins=' "$KAS" | grep -q 'NodeRestriction'; then echo "  PASS"; ((PASS++)); else echo "  FAIL: NodeRestriction not enabled"; ((FAIL++)); fi

echo ""; echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
