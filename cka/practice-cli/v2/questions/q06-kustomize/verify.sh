#!/bin/bash
# Q6 — Kustomize Deployment Tasks: Verify
PASS=0; FAIL=0

echo "Checking /root/kustomize-lab/overlays/production/kustomization.yaml exists..."
if [[ -f /root/kustomize-lab/overlays/production/kustomization.yaml ]]; then
  echo "  PASS: Production overlay kustomization.yaml exists"
  ((PASS++))
else
  echo "  FAIL: /root/kustomize-lab/overlays/production/kustomization.yaml not found"
  ((FAIL++))
fi

echo "Checking deployment exists in production namespace..."
if kubectl get deployment my-app -n production &>/dev/null; then
  echo "  PASS: Deployment my-app found in production namespace"
  ((PASS++))
else
  echo "  FAIL: Deployment my-app not found in production namespace"
  ((FAIL++))
fi

echo "Checking deployment has more than 1 replica..."
REPLICAS=$(kubectl get deployment my-app -n production -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "0")
if [[ "$REPLICAS" -ge 3 ]]; then
  echo "  PASS: Deployment has $REPLICAS replicas"
  ((PASS++))
else
  echo "  FAIL: Deployment has $REPLICAS replica(s) (expected at least 3)"
  ((FAIL++))
fi

echo "Checking pods are running in production namespace..."
RUNNING_PODS=$(kubectl get pods -n production --no-headers 2>/dev/null | grep -c "Running" || true)
if [[ "$RUNNING_PODS" -ge 1 ]]; then
  echo "  PASS: $RUNNING_PODS pod(s) running in production namespace"
  ((PASS++))
else
  echo "  FAIL: No running pods found in production namespace"
  ((FAIL++))
fi

echo "Checking image tag is updated (not nginx:1.24)..."
IMAGE=$(kubectl get deployment my-app -n production -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null || echo "")
if [[ -n "$IMAGE" && "$IMAGE" != "nginx:1.24" ]]; then
  echo "  PASS: Image updated to $IMAGE"
  ((PASS++))
else
  echo "  FAIL: Image is still nginx:1.24 or not set (current: $IMAGE)"
  ((FAIL++))
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
