#!/bin/bash
# Q21 — CNI / Networking Troubleshooting: Verify
PASS=0; FAIL=0

echo "Checking calico-custom-resources.yaml has correct CIDR..."
EXPECTED_CIDR=$(cat /root/cni-troubleshoot/expected-cidr.txt 2>/dev/null | tr -d '[:space:]')
if [[ -z "$EXPECTED_CIDR" ]]; then
  EXPECTED_CIDR="10.244.0.0/16"
fi
ACTUAL_CIDR=$(grep "cidr:" /root/cni-troubleshoot/calico-custom-resources.yaml 2>/dev/null | awk '{print $2}' | tr -d '[:space:]')
if [[ "$ACTUAL_CIDR" == "$EXPECTED_CIDR" ]]; then
  echo "  PASS: calico-custom-resources.yaml CIDR is $EXPECTED_CIDR"
  ((PASS++))
else
  echo "  FAIL: calico-custom-resources.yaml CIDR is '$ACTUAL_CIDR' (expected: $EXPECTED_CIDR)"
  ((FAIL++))
fi

echo "Checking all nodes are Ready..."
NOT_READY=$(kubectl get nodes --no-headers 2>/dev/null | grep -c "NotReady" || true)
if [[ "$NOT_READY" -eq 0 ]]; then
  echo "  PASS: All nodes are Ready"
  ((PASS++))
else
  echo "  FAIL: $NOT_READY node(s) are NotReady"
  ((FAIL++))
fi

echo "Checking pods in cni-debug namespace are Running..."
TOTAL=$(kubectl get pods -n cni-debug --no-headers 2>/dev/null | wc -l | tr -d ' ')
NOT_RUNNING=$(kubectl get pods -n cni-debug --no-headers 2>/dev/null | grep -v -E "Running|Completed" | wc -l | tr -d ' ')
if [[ "$TOTAL" -gt 0 && "$NOT_RUNNING" -eq 0 ]]; then
  echo "  PASS: All pods in cni-debug namespace are Running"
  ((PASS++))
else
  echo "  FAIL: $NOT_RUNNING pod(s) in cni-debug namespace not Running (total: $TOTAL)"
  ((FAIL++))
fi

echo "Checking Calico pods are running (if applicable)..."
CALICO_PODS=$(kubectl get pods -n calico-system --no-headers 2>/dev/null | wc -l | tr -d ' ')
if [[ "$CALICO_PODS" -gt 0 ]]; then
  CALICO_NOT_RUNNING=$(kubectl get pods -n calico-system --no-headers 2>/dev/null | grep -v -E "Running|Completed" | wc -l | tr -d ' ')
  if [[ "$CALICO_NOT_RUNNING" -eq 0 ]]; then
    echo "  PASS: All Calico pods are Running"
    ((PASS++))
  else
    echo "  FAIL: $CALICO_NOT_RUNNING Calico pod(s) not Running"
    ((FAIL++))
  fi
else
  # Try kube-system namespace for Calico
  CALICO_KUBE=$(kubectl get pods -n kube-system --no-headers 2>/dev/null | grep -c "calico" || true)
  if [[ "$CALICO_KUBE" -gt 0 ]]; then
    CALICO_NOT_RUNNING=$(kubectl get pods -n kube-system --no-headers 2>/dev/null | grep "calico" | grep -v -E "Running|Completed" | wc -l | tr -d ' ')
    if [[ "$CALICO_NOT_RUNNING" -eq 0 ]]; then
      echo "  PASS: All Calico pods are Running (kube-system)"
      ((PASS++))
    else
      echo "  FAIL: $CALICO_NOT_RUNNING Calico pod(s) not Running (kube-system)"
      ((FAIL++))
    fi
  else
    echo "  PASS: No Calico pods found (skipping check)"
    ((PASS++))
  fi
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
