#!/bin/bash
# Q8 — Verify
PASS=0; FAIL=0
echo "Checking pod 'audited' uses RuntimeDefault..."
T=$(kubectl get pod audited -o jsonpath='{.spec.securityContext.seccompProfile.type}' 2>/dev/null)
[[ -z "$T" ]] && T=$(kubectl get pod audited -o jsonpath='{.spec.containers[0].securityContext.seccompProfile.type}' 2>/dev/null)
if [[ "$T" == "RuntimeDefault" ]]; then echo "  PASS"; ((PASS++)); else echo "  FAIL: audited seccomp type is '$T'"; ((FAIL++)); fi
echo "Checking pod 'custom' uses Localhost profiles/audit.json..."
LT=$(kubectl get pod custom -o jsonpath='{.spec.securityContext.seccompProfile.type}' 2>/dev/null)
LP=$(kubectl get pod custom -o jsonpath='{.spec.securityContext.seccompProfile.localhostProfile}' 2>/dev/null)
[[ -z "$LT" ]] && LT=$(kubectl get pod custom -o jsonpath='{.spec.containers[0].securityContext.seccompProfile.type}' 2>/dev/null)
[[ -z "$LP" ]] && LP=$(kubectl get pod custom -o jsonpath='{.spec.containers[0].securityContext.seccompProfile.localhostProfile}' 2>/dev/null)
if [[ "$LT" == "Localhost" && "$LP" == "profiles/audit.json" ]]; then echo "  PASS"; ((PASS++)); else echo "  FAIL: custom seccomp is type='$LT' profile='$LP'"; ((FAIL++)); fi
echo ""; echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
