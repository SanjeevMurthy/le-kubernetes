#!/bin/bash
# Q17 — Verify (control-plane node)
PASS=0; FAIL=0
KAS=/etc/kubernetes/manifests/kube-apiserver.yaml
POL=/etc/kubernetes/audit/policy.yaml
if [ ! -f "$KAS" ]; then echo "  FAIL: $KAS not found — run on the control-plane node"; echo "Results: 0 passed, 1 failed"; exit 1; fi
echo "Checking --audit-policy-file and --audit-log-path flags..."
if grep -q -- '--audit-policy-file=' "$KAS" && grep -q -- '--audit-log-path=' "$KAS"; then echo "  PASS"; ((PASS++)); else echo "  FAIL: audit flags not set on apiserver"; ((FAIL++)); fi
echo "Checking audit policy logs secrets at RequestResponse..."
if [ -f "$POL" ] && grep -q 'secrets' "$POL" && grep -q 'RequestResponse' "$POL"; then echo "  PASS"; ((PASS++)); else echo "  FAIL: policy.yaml missing or no secrets/RequestResponse rule"; ((FAIL++)); fi
echo ""; echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
