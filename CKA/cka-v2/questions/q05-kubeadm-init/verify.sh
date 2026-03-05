#!/bin/bash
# Q5 — kubeadm Cluster Installation: Verify
PASS=0; FAIL=0

echo "Checking kubectl can access the cluster..."
if kubectl get nodes &>/dev/null; then
  echo "  PASS: kubectl can reach the cluster"
  ((PASS++))
else
  echo "  FAIL: kubectl cannot access the cluster"
  ((FAIL++))
fi

echo "Checking kubeconfig exists at \$HOME/.kube/config..."
if [[ -f "$HOME/.kube/config" ]]; then
  echo "  PASS: kubeconfig found at $HOME/.kube/config"
  ((PASS++))
else
  echo "  FAIL: kubeconfig not found at $HOME/.kube/config"
  ((FAIL++))
fi

echo "Checking Pod CIDR is configured..."
POD_CIDR=$(kubectl cluster-info dump 2>/dev/null | grep -m1 "cluster-cidr" || true)
if [[ -n "$POD_CIDR" ]]; then
  echo "  PASS: Pod CIDR is configured"
  ((PASS++))
else
  # Fallback: check kubeadm-config or node pod CIDR
  NODE_CIDR=$(kubectl get nodes -o jsonpath='{.items[0].spec.podCIDR}' 2>/dev/null || true)
  if [[ -n "$NODE_CIDR" ]]; then
    echo "  PASS: Pod CIDR is configured ($NODE_CIDR)"
    ((PASS++))
  else
    echo "  FAIL: Pod CIDR does not appear to be configured"
    ((FAIL++))
  fi
fi

echo "Checking kube-system pods are running..."
RUNNING_PODS=$(kubectl get pods -n kube-system --no-headers 2>/dev/null | grep -c "Running" || true)
if [[ "$RUNNING_PODS" -ge 3 ]]; then
  echo "  PASS: $RUNNING_PODS kube-system pod(s) running"
  ((PASS++))
else
  echo "  FAIL: Only $RUNNING_PODS kube-system pod(s) running (expected at least 3)"
  ((FAIL++))
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
