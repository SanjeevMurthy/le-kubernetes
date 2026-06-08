#!/bin/bash
# Q12 — Verify
PASS=0; FAIL=0
echo "Checking RuntimeClass 'gvisor' (handler runsc)..."
H=$(kubectl get runtimeclass gvisor -o jsonpath='{.handler}' 2>/dev/null)
if [[ "$H" == "runsc" ]]; then echo "  PASS"; ((PASS++)); else echo "  FAIL: runtimeclass gvisor handler is '$H' (expected runsc)"; ((FAIL++)); fi
echo "Checking pod 'sandboxed' uses runtimeClassName gvisor..."
R=$(kubectl get pod sandboxed -o jsonpath='{.spec.runtimeClassName}' 2>/dev/null)
if [[ "$R" == "gvisor" ]]; then echo "  PASS"; ((PASS++)); else echo "  FAIL: pod runtimeClassName is '$R'"; ((FAIL++)); fi
echo ""; echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
