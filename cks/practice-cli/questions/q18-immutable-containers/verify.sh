#!/bin/bash
# Q18 — Verify
PASS=0; FAIL=0
B="kubectl get deploy api -n prod -o jsonpath"
RORF=$($B='{.spec.template.spec.containers[0].securityContext.readOnlyRootFilesystem}' 2>/dev/null)
APE=$($B='{.spec.template.spec.containers[0].securityContext.allowPrivilegeEscalation}' 2>/dev/null)
MNT=$(kubectl get deploy api -n prod -o json 2>/dev/null | grep -o '"mountPath":"/tmp"')
echo "readOnlyRootFilesystem == true ..."; if [[ "$RORF" == "true" ]]; then echo "  PASS"; ((PASS++)); else echo "  FAIL ($RORF)"; ((FAIL++)); fi
echo "allowPrivilegeEscalation == false ..."; if [[ "$APE" == "false" ]]; then echo "  PASS"; ((PASS++)); else echo "  FAIL ($APE)"; ((FAIL++)); fi
echo "writable volume mounted at /tmp ..."; if [[ -n "$MNT" ]]; then echo "  PASS"; ((PASS++)); else echo "  FAIL: no /tmp mount (container will crash on read-only root)"; ((FAIL++)); fi
echo ""; echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
