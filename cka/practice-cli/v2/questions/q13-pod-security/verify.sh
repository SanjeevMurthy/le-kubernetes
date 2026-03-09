#!/bin/bash
# Q13 — Enforce Pod Security Standards: Verify
PASS=0; FAIL=0

echo "Checking namespace secure-ns exists..."
if kubectl get namespace secure-ns &>/dev/null; then
  echo "  PASS: Namespace secure-ns exists"
  ((PASS++))
else
  echo "  FAIL: Namespace secure-ns not found"
  ((FAIL++))
fi

echo "Checking namespace has pod-security.kubernetes.io/enforce=restricted label..."
ENFORCE=$(kubectl get namespace secure-ns -o jsonpath='{.metadata.labels.pod-security\.kubernetes\.io/enforce}' 2>/dev/null || echo "")
if [[ "$ENFORCE" == "restricted" ]]; then
  echo "  PASS: enforce=restricted label is set"
  ((PASS++))
else
  echo "  FAIL: enforce label is '$ENFORCE' (expected: restricted)"
  ((FAIL++))
fi

echo "Checking privileged pod is rejected..."
PRIV_OUTPUT=$(kubectl run test-privileged --image=nginx --restart=Never -n secure-ns --overrides='{
  "spec": {
    "containers": [{
      "name": "test-privileged",
      "image": "nginx",
      "securityContext": {
        "privileged": true
      }
    }]
  }
}' 2>&1 || true)
# Clean up in case it was somehow created
kubectl delete pod test-privileged -n secure-ns --ignore-not-found &>/dev/null
if echo "$PRIV_OUTPUT" | grep -qi "forbidden\|violat"; then
  echo "  PASS: Privileged pod was correctly rejected"
  ((PASS++))
else
  echo "  FAIL: Privileged pod was not rejected (output: $PRIV_OUTPUT)"
  ((FAIL++))
fi

echo "Checking compliant pod can be created..."
kubectl delete pod test-compliant -n secure-ns --ignore-not-found &>/dev/null
COMPLIANT_OUTPUT=$(kubectl run test-compliant --image=nginx --restart=Never -n secure-ns --overrides='{
  "spec": {
    "containers": [{
      "name": "test-compliant",
      "image": "nginx",
      "securityContext": {
        "allowPrivilegeEscalation": false,
        "runAsNonRoot": true,
        "runAsUser": 1000,
        "seccompProfile": {
          "type": "RuntimeDefault"
        },
        "capabilities": {
          "drop": ["ALL"]
        }
      }
    }]
  }
}' 2>&1)
if kubectl get pod test-compliant -n secure-ns &>/dev/null; then
  echo "  PASS: Compliant pod was created successfully"
  ((PASS++))
  kubectl delete pod test-compliant -n secure-ns --ignore-not-found &>/dev/null
else
  echo "  FAIL: Compliant pod could not be created (output: $COMPLIANT_OUTPUT)"
  ((FAIL++))
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
