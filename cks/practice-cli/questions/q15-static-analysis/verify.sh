#!/bin/bash
# Q15 — Static analysis & manifest hardening: Verify
PASS=0; FAIL=0

jp() { kubectl get deploy app -n appsec -o jsonpath="$1" 2>/dev/null; }

RORF=$(jp '{.spec.template.spec.containers[0].securityContext.readOnlyRootFilesystem}')
APE=$(jp '{.spec.template.spec.containers[0].securityContext.allowPrivilegeEscalation}')
DROP=$(jp '{.spec.template.spec.containers[0].securityContext.capabilities.drop[*]}' | tr ' ' '\n' | grep -x 'ALL')
NONROOT=$(jp '{.spec.template.spec.containers[0].securityContext.runAsNonRoot}')
[[ -z "$NONROOT" ]] && NONROOT=$(jp '{.spec.template.spec.securityContext.runAsNonRoot}')

echo "readOnlyRootFilesystem == true ..."
if [[ "$RORF" == "true" ]]; then echo "  PASS"; ((PASS++)); else echo "  FAIL (got '$RORF')"; ((FAIL++)); fi

echo "allowPrivilegeEscalation == false ..."
if [[ "$APE" == "false" ]]; then echo "  PASS"; ((PASS++)); else echo "  FAIL (got '$APE')"; ((FAIL++)); fi

echo "capabilities drop ALL ..."
if [[ -n "$DROP" ]]; then echo "  PASS"; ((PASS++)); else echo "  FAIL (capabilities.drop does not contain ALL)"; ((FAIL++)); fi

echo "runAsNonRoot == true ..."
if [[ "$NONROOT" == "true" ]]; then echo "  PASS"; ((PASS++)); else echo "  FAIL (got '$NONROOT')"; ((FAIL++)); fi

echo ""; echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
