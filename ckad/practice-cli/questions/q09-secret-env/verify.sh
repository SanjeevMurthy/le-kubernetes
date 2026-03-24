#!/bin/bash
# Q9 — Create Secret and Pod with Env Vars: Verify
PASS=0; FAIL=0

echo "Checking Secret app-secret exists..."
if kubectl get secret app-secret &>/dev/null; then
  echo "  PASS: Secret app-secret exists"
  ((PASS++))
else
  echo "  FAIL: Secret app-secret not found"
  ((FAIL++))
fi

echo "Checking Pod secret-pod exists..."
if kubectl get pod secret-pod &>/dev/null; then
  echo "  PASS: Pod secret-pod exists"
  ((PASS++))
else
  echo "  FAIL: Pod secret-pod not found"
  ((FAIL++))
fi

echo "Checking container name is secret-container..."
CONTAINER_NAME=$(kubectl get pod secret-pod -o jsonpath='{.spec.containers[0].name}' 2>/dev/null || echo "")
if [[ "$CONTAINER_NAME" == "secret-container" ]]; then
  echo "  PASS: Container name is secret-container"
  ((PASS++))
else
  echo "  FAIL: Container name is '$CONTAINER_NAME' (expected: secret-container)"
  ((FAIL++))
fi

echo "Checking container has env vars from secretKeyRef referencing app-secret..."
SECRET_REF_COUNT=$(kubectl get pod secret-pod -o json 2>/dev/null | python3 -c "
import sys, json
spec = json.load(sys.stdin)
containers = spec['spec']['containers']
count = 0
for c in containers:
    if c.get('name') != 'secret-container':
        continue
    for e in c.get('env', []):
        ref = e.get('valueFrom', {}).get('secretKeyRef', {})
        if ref.get('name') == 'app-secret':
            count += 1
    for ef in c.get('envFrom', []):
        ref = ef.get('secretRef', {})
        if ref.get('name') == 'app-secret':
            count += 1
            break
print(count)
" 2>/dev/null || echo "0")
if [[ "$SECRET_REF_COUNT" -ge 1 ]]; then
  echo "  PASS: Container references app-secret ($SECRET_REF_COUNT reference(s))"
  ((PASS++))
else
  echo "  FAIL: Container has $SECRET_REF_COUNT references to app-secret (expected: >= 1)"
  ((FAIL++))
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
