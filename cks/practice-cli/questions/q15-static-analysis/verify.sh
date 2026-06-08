#!/bin/bash
# Q15 — Verify
PASS=0; FAIL=0
B="kubectl get deploy app -n appsec -o jsonpath"
RORF=$($B='{.spec.template.spec.containers[0].securityContext.readOnlyRootFilesystem}' 2>/dev/null)
APE=$($B='{.spec.template.spec.containers[0].securityContext.allowPrivilegeEscalation}' 2>/dev/null)
DROP=$(kubectl get deploy app -n appsec -o json 2>/dev/null | grep -o '"drop":\["ALL"\]')
NONROOT=$($B='{.spec.template.spec.containers[0].securityContext.runAsNonRoot}' 2>/dev/null)
[[ -z "$NONROOT" ]] && NONROOT=$($B='{.spec.template.spec.securityContext.runAsNonRoot}' 2>/dev/null)

echo "readOnlyRootFilesystem == true ..."; if [[ "$RORF" == "true" ]]; then echo "  PASS"; ((PASS++)); else echo "  FAIL ($RORF)"; ((FAIL++)); fi
echo "allowPrivilegeEscalation == false ..."; if [[ "$APE" == "false" ]]; then echo "  PASS"; ((PASS++)); else echo "  FAIL ($APE)"; ((FAIL++)); fi
echo "capabilities drop ALL ..."; if [[ -n "$DROP" ]]; then echo "  PASS"; ((PASS++)); else echo "  FAIL"; ((FAIL++)); fi
echo "runAsNonRoot == true ..."; if [[ "$NONROOT" == "true" ]]; then echo "  PASS"; ((PASS++)); else echo "  FAIL ($NONROOT)"; ((FAIL++)); fi
echo ""; echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
