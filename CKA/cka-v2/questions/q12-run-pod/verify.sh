#!/bin/bash
# Q12 — Run a Single-Container Pod: Verify
PASS=0; FAIL=0

echo "Checking pod nginx-pod exists in default namespace..."
if kubectl get pod nginx-pod -n default &>/dev/null; then
  echo "  PASS: Pod nginx-pod exists"
  ((PASS++))
else
  echo "  FAIL: Pod nginx-pod not found in default namespace"
  ((FAIL++))
fi

echo "Checking pod is Running..."
PHASE=$(kubectl get pod nginx-pod -n default -o jsonpath='{.status.phase}' 2>/dev/null || echo "")
if [[ "$PHASE" == "Running" ]]; then
  echo "  PASS: Pod is Running"
  ((PASS++))
else
  echo "  FAIL: Pod phase is '$PHASE' (expected: Running)"
  ((FAIL++))
fi

echo "Checking pod uses image nginx:1.25..."
IMAGE=$(kubectl get pod nginx-pod -n default -o jsonpath='{.spec.containers[0].image}' 2>/dev/null || echo "")
if [[ "$IMAGE" == "nginx:1.25" ]]; then
  echo "  PASS: Image is nginx:1.25"
  ((PASS++))
else
  echo "  FAIL: Image is '$IMAGE' (expected: nginx:1.25)"
  ((FAIL++))
fi

echo "Checking pod has containerPort 80..."
PORT=$(kubectl get pod nginx-pod -n default -o jsonpath='{.spec.containers[0].ports[0].containerPort}' 2>/dev/null || echo "")
if [[ "$PORT" == "80" ]]; then
  echo "  PASS: containerPort is 80"
  ((PASS++))
else
  echo "  FAIL: containerPort is '$PORT' (expected: 80)"
  ((FAIL++))
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
