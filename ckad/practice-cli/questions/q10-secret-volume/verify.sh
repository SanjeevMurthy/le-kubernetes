#!/bin/bash
# Q10 — Secret as Volume Mount: Verify
PASS=0; FAIL=0

echo "Checking Secret secret2 exists..."
if kubectl get secret secret2 &>/dev/null; then
  echo "  PASS: Secret secret2 exists"
  ((PASS++))
else
  echo "  FAIL: Secret secret2 not found"
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

echo "Checking Pod is Running..."
PHASE=$(kubectl get pod secret-pod -o jsonpath='{.status.phase}' 2>/dev/null || echo "")
if [[ "$PHASE" == "Running" ]]; then
  echo "  PASS: Pod is Running"
  ((PASS++))
else
  echo "  FAIL: Pod phase is '$PHASE' (expected: Running)"
  ((FAIL++))
fi

echo "Checking pod has volume mount at /etc/secrets..."
MOUNT_PATH=$(kubectl get pod secret-pod -o json 2>/dev/null | python3 -c "
import sys, json
spec = json.load(sys.stdin)
for c in spec['spec']['containers']:
    for vm in c.get('volumeMounts', []):
        if vm.get('mountPath') == '/etc/secrets':
            print('found')
            sys.exit(0)
print('missing')
" 2>/dev/null || echo "error")
if [[ "$MOUNT_PATH" == "found" ]]; then
  echo "  PASS: Volume mounted at /etc/secrets"
  ((PASS++))
else
  echo "  FAIL: No volume mount at /etc/secrets (expected: mount at /etc/secrets)"
  ((FAIL++))
fi

echo "Checking mounted file content is accessible..."
CONTENT=$(kubectl exec secret-pod -- cat /etc/secrets/db-config.txt 2>/dev/null || echo "")
if echo "$CONTENT" | grep -q "username=admin" && echo "$CONTENT" | grep -q "password=s3cure!"; then
  echo "  PASS: Mounted db-config.txt has correct content"
  ((PASS++))
else
  echo "  FAIL: db-config.txt content is '$CONTENT' (expected: username=admin and password=s3cure!)"
  ((FAIL++))
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
