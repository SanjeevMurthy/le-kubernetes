#!/bin/bash
# Q18 — Immutable containers (readOnlyRootFilesystem): Verify
PASS=0; FAIL=0

jp() { kubectl get deploy api -n prod -o jsonpath="$1" 2>/dev/null; }

RORF=$(jp '{.spec.template.spec.containers[0].securityContext.readOnlyRootFilesystem}')
APE=$(jp '{.spec.template.spec.containers[0].securityContext.allowPrivilegeEscalation}')
MNT=$(jp '{.spec.template.spec.containers[0].volumeMounts[*].mountPath}' | tr ' ' '\n' | grep -x '/tmp')

echo "readOnlyRootFilesystem == true ..."
if [[ "$RORF" == "true" ]]; then echo "  PASS"; ((PASS++)); else echo "  FAIL (got '$RORF')"; ((FAIL++)); fi

echo "allowPrivilegeEscalation == false ..."
if [[ "$APE" == "false" ]]; then echo "  PASS"; ((PASS++)); else echo "  FAIL (got '$APE')"; ((FAIL++)); fi

echo "writable volume mounted at /tmp ..."
if [[ -n "$MNT" ]]; then echo "  PASS"; ((PASS++)); else echo "  FAIL: no /tmp mount (the container will crash on a read-only root)"; ((FAIL++)); fi

echo ""; echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
