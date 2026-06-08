#!/bin/bash
# Q11 — Verify
PASS=0; FAIL=0
if ! kubectl get crd clusterpolicies.kyverno.io &>/dev/null; then echo "  FAIL: Kyverno CRDs not installed"; echo "Results: 0 passed, 1 failed"; exit 1; fi
echo "Checking ClusterPolicy 'restrict-registries' exists..."
if kubectl get clusterpolicy restrict-registries &>/dev/null; then echo "  PASS"; ((PASS++)); else echo "  FAIL: ClusterPolicy restrict-registries not found"; ((FAIL++)); fi
echo "Checking it enforces (validationFailureAction Enforce)..."
A=$(kubectl get clusterpolicy restrict-registries -o jsonpath='{.spec.validationFailureAction}' 2>/dev/null)
if [[ "$A" == "Enforce" || "$A" == "enforce" ]]; then echo "  PASS"; ((PASS++)); else echo "  FAIL: validationFailureAction is '$A' (expected Enforce)"; ((FAIL++)); fi
echo "Checking it restricts to registry.internal..."
if kubectl get clusterpolicy restrict-registries -o json 2>/dev/null | grep -q 'registry.internal'; then echo "  PASS"; ((PASS++)); else echo "  FAIL: policy does not reference registry.internal"; ((FAIL++)); fi
echo ""; echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
