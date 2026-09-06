#!/bin/bash
# Q11 Kyverno admission policy: verify.
source "$(dirname "$0")/../../lib/checks.sh"
source "$(dirname "$0")/../../lib/env.sh"

NS=kyverno-lab
POL=restrict-registries

if ! kubectl get crd clusterpolicies.kyverno.io >/dev/null 2>&1; then
  echo "  FAIL: Kyverno CRDs are not installed in this cluster"
  echo ""
  echo "Results: 0 passed, 1 failed"
  exit 1
fi

echo "Checking the ClusterPolicy object..."
check "ClusterPolicy $POL exists" kubectl get clusterpolicy "$POL"

# Kyverno moved the setting from spec.validationFailureAction to a per-rule
# validate.failureAction, so accept either spelling.
ACTION=$(kjp clusterpolicy "$POL" "" '{.spec.validationFailureAction}')
[[ -z "$ACTION" ]] && ACTION=$(kjp clusterpolicy "$POL" "" '{.spec.rules[*].validate.failureAction}')
ACTION=$(echo "$ACTION" | tr '[:upper:]' '[:lower:]' | tr ' ' '\n' | head -1)
check_eq "the policy enforces (rejects) rather than audits" "enforce" "$ACTION"
check_contains "the policy names the allowed registry" "registry.internal" "$(kubectl get clusterpolicy "$POL" -o yaml 2>/dev/null)"

echo "Checking admission really blocks foreign registries (effect test)..."
check "namespace $NS exists to test against" kubectl get namespace "$NS"
check_not "a docker.io image is rejected by the API server" \
  kubectl run bad --image=docker.io/library/nginx:1.27 -n "$NS" --dry-run=server
check "a registry.internal image is still admitted" \
  kubectl run good --image=registry.internal/nginx:1.27 -n "$NS" --dry-run=server

summary
