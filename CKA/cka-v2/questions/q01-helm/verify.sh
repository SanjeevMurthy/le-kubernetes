#!/bin/bash
# Q1 — Helm Template Generation and Chart Installation: Verify
PASS=0; FAIL=0

echo "Checking namespace argocd exists..."
if kubectl get ns argocd &>/dev/null; then
  echo "  PASS: Namespace argocd exists"
  ((PASS++))
else
  echo "  FAIL: Namespace argocd not found"
  ((FAIL++))
fi

echo "Checking /root/argo-helm.yaml exists and is non-empty..."
if [[ -s /root/argo-helm.yaml ]]; then
  echo "  PASS: /root/argo-helm.yaml exists and is non-empty"
  ((PASS++))
else
  echo "  FAIL: /root/argo-helm.yaml missing or empty"
  ((FAIL++))
fi

echo "Checking helm release exists in argocd namespace..."
if helm list -n argocd 2>/dev/null | grep -q argocd; then
  echo "  PASS: Helm release found in argocd namespace"
  ((PASS++))
else
  echo "  FAIL: No helm release found in argocd namespace"
  ((FAIL++))
fi

echo "Checking argocd pods are running..."
RUNNING_PODS=$(kubectl get pods -n argocd --no-headers 2>/dev/null | grep -c "Running" || true)
if [[ "$RUNNING_PODS" -ge 1 ]]; then
  echo "  PASS: $RUNNING_PODS argocd pod(s) running"
  ((PASS++))
else
  echo "  FAIL: No running pods found in argocd namespace"
  ((FAIL++))
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
