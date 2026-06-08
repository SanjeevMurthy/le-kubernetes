#!/bin/bash
# Q9 — Create Secret and Pod with Env Vars: Verify
PASS=0; FAIL=0

echo "Checking Secret secret1 exists..."
if kubectl get secret secret1 &>/dev/null; then
  echo "  PASS: Secret secret1 exists"
  ((PASS++))
else
  echo "  FAIL: Secret secret1 not found"
  ((FAIL++))
fi

echo "Checking Pod api-pod exists..."
if kubectl get pod api-pod &>/dev/null; then
  echo "  PASS: Pod api-pod exists"
  ((PASS++))
else
  echo "  FAIL: Pod api-pod not found"
  ((FAIL++))
fi

echo "Checking container name is xy..."
CONTAINER_NAME=$(kubectl get pod api-pod -o jsonpath='{.spec.containers[0].name}' 2>/dev/null || echo "")
if [[ "$CONTAINER_NAME" == "xy" ]]; then
  echo "  PASS: Container name is xy"
  ((PASS++))
else
  echo "  FAIL: Container name is '$CONTAINER_NAME' (expected: xy)"
  ((FAIL++))
fi

echo "Checking container has env vars from secretKeyRef referencing secret1..."
SECRET_REF_COUNT=$(kubectl get pod api-pod -o json 2>/dev/null | python3 -c "
import sys, json
spec = json.load(sys.stdin)
containers = spec['spec']['containers']
count = 0
for c in containers:
    if c.get('name') != 'xy':
        continue
    for e in c.get('env', []):
        ref = e.get('valueFrom', {}).get('secretKeyRef', {})
        if ref.get('name') == 'secret1':
            count += 1
    for ef in c.get('envFrom', []):
        ref = ef.get('secretRef', {})
        if ref.get('name') == 'secret1':
            count += 1
            break
print(count)
" 2>/dev/null || echo "0")
if [[ "$SECRET_REF_COUNT" -ge 1 ]]; then
  echo "  PASS: Container references secret1 ($SECRET_REF_COUNT reference(s))"
  ((PASS++))
else
  echo "  FAIL: Container has $SECRET_REF_COUNT references to secret1 (expected: >= 1)"
  ((FAIL++))
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
