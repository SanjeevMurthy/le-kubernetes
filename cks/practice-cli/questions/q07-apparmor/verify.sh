#!/bin/bash
# Q7 — Verify
PASS=0; FAIL=0
echo "Checking pod 'secure-pod' exists..."
if kubectl get pod secure-pod &>/dev/null; then echo "  PASS"; ((PASS++)); else echo "  FAIL: pod secure-pod not found"; ((FAIL++)); fi
echo "Checking it references AppArmor profile k8s-deny-write..."
FIELD=$(kubectl get pod secure-pod -o jsonpath='{.spec.containers[0].securityContext.appArmorProfile.localhostProfile}' 2>/dev/null)
ANNO=$(kubectl get pod secure-pod -o json 2>/dev/null | grep -o 'localhost/k8s-deny-write')
if [[ "$FIELD" == "k8s-deny-write" || -n "$ANNO" ]]; then echo "  PASS: profile k8s-deny-write applied"; ((PASS++)); else echo "  FAIL: k8s-deny-write not applied (field or annotation)"; ((FAIL++)); fi
echo ""; echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
