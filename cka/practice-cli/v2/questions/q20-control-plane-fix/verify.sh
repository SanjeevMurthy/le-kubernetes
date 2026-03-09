#!/bin/bash
# Q20 — Control Plane Troubleshooting: Verify
PASS=0; FAIL=0

echo "Checking kube-apiserver is responding..."
if kubectl get nodes &>/dev/null; then
  echo "  PASS: API server is responding"
  ((PASS++))
else
  echo "  FAIL: API server is not responding"
  ((FAIL++))
fi

echo "Checking etcd endpoint uses port 2379 in kube-apiserver manifest..."
ETCD_PORT=$(grep "etcd-servers" /etc/kubernetes/manifests/kube-apiserver.yaml 2>/dev/null | grep -c "2379" || true)
if [[ "$ETCD_PORT" -gt 0 ]]; then
  echo "  PASS: etcd client port is 2379"
  ((PASS++))
else
  echo "  FAIL: etcd client port is not 2379"
  ((FAIL++))
fi

echo "Checking kube-system pods are running..."
NOT_RUNNING=$(kubectl get pods -n kube-system --no-headers 2>/dev/null | grep -v -E "Running|Completed" | wc -l | tr -d ' ')
if [[ "$NOT_RUNNING" -eq 0 ]]; then
  echo "  PASS: All kube-system pods are running"
  ((PASS++))
else
  echo "  FAIL: $NOT_RUNNING kube-system pod(s) not in Running/Completed state"
  ((FAIL++))
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
