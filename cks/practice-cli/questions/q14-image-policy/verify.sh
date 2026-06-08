#!/bin/bash
# Q14 — Verify (either approach passes)
PASS=0; FAIL=0
OK=0
# Option A: Kyverno enforce policy referencing registry.internal
if kubectl get crd clusterpolicies.kyverno.io &>/dev/null; then
  if kubectl get clusterpolicy -o json 2>/dev/null | grep -q 'registry.internal' && \
     kubectl get clusterpolicy -o json 2>/dev/null | grep -qi '"validationFailureAction":"[Ee]nforce"'; then
    OK=1; echo "  PASS: Kyverno Enforce policy restricting registry.internal found"
  fi
fi
# Option B: ImagePolicyWebhook on apiserver
KAS=/etc/kubernetes/manifests/kube-apiserver.yaml
if [[ "$OK" -eq 0 && -f "$KAS" ]]; then
  if grep -- '--enable-admission-plugins=' "$KAS" | grep -q 'ImagePolicyWebhook' && grep -q -- '--admission-control-config-file=' "$KAS"; then
    OK=1; echo "  PASS: ImagePolicyWebhook configured on the apiserver"
  fi
fi
if [[ "$OK" -eq 1 ]]; then ((PASS++)); else echo "  FAIL: no registry restriction found (Kyverno Enforce policy or ImagePolicyWebhook)"; ((FAIL++)); fi
echo ""; echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
