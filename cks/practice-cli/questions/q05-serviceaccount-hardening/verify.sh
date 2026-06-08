#!/bin/bash
# Q5 — Verify
PASS=0; FAIL=0

echo "Checking SA app-sa has automountServiceAccountToken: false..."
AM=$(kubectl get sa app-sa -n app -o jsonpath='{.automountServiceAccountToken}' 2>/dev/null)
if [[ "$AM" == "false" ]]; then echo "  PASS: SA automount disabled"; ((PASS++)); else echo "  FAIL: SA automount is '$AM' (expected false)"; ((FAIL++)); fi

echo "Checking pod 'legacy' uses app-sa..."
PSA=$(kubectl get pod legacy -n app -o jsonpath='{.spec.serviceAccountName}' 2>/dev/null)
if [[ "$PSA" == "app-sa" ]]; then echo "  PASS: pod uses app-sa"; ((PASS++)); else echo "  FAIL: pod serviceAccountName is '$PSA'"; ((FAIL++)); fi

echo "Checking pod has no token mounted..."
PAM=$(kubectl get pod legacy -n app -o jsonpath='{.spec.automountServiceAccountToken}' 2>/dev/null)
MNT=$(kubectl get pod legacy -n app -o json 2>/dev/null | grep -c 'kube-api-access' )
if [[ "$PAM" == "false" || "$MNT" == "0" ]]; then echo "  PASS: no SA token mounted"; ((PASS++)); else echo "  FAIL: SA token appears mounted"; ((FAIL++)); fi

echo ""; echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
