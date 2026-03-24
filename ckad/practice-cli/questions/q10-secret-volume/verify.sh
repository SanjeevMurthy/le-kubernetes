#!/bin/bash
# Q10 — Secret as Volume Mount: Verify
PASS=0; FAIL=0

echo "Checking Secret credentials-secret exists..."
if kubectl get secret credentials-secret &>/dev/null; then
  echo "  PASS: Secret credentials-secret exists"
  ((PASS++))
else
  echo "  FAIL: Secret credentials-secret not found"
  ((FAIL++))
fi

echo "Checking Pod secret-vol-pod exists..."
if kubectl get pod secret-vol-pod &>/dev/null; then
  echo "  PASS: Pod secret-vol-pod exists"
  ((PASS++))
else
  echo "  FAIL: Pod secret-vol-pod not found"
  ((FAIL++))
fi

echo "Checking Pod is Running..."
PHASE=$(kubectl get pod secret-vol-pod -o jsonpath='{.status.phase}' 2>/dev/null || echo "")
if [[ "$PHASE" == "Running" ]]; then
  echo "  PASS: Pod is Running"
  ((PASS++))
else
  echo "  FAIL: Pod phase is '$PHASE' (expected: Running)"
  ((FAIL++))
fi

echo "Checking pod has volume mount at /etc/credentials..."
MOUNT_PATH=$(kubectl get pod secret-vol-pod -o json 2>/dev/null | python3 -c "
import sys, json
spec = json.load(sys.stdin)
for c in spec['spec']['containers']:
    for vm in c.get('volumeMounts', []):
        if vm.get('mountPath') == '/etc/credentials':
            print('found')
            sys.exit(0)
print('missing')
" 2>/dev/null || echo "error")
if [[ "$MOUNT_PATH" == "found" ]]; then
  echo "  PASS: Volume mounted at /etc/credentials"
  ((PASS++))
else
  echo "  FAIL: No volume mount at /etc/credentials (expected: mount at /etc/credentials)"
  ((FAIL++))
fi

echo "Checking mounted file content is accessible..."
CONTENT=$(kubectl exec secret-vol-pod -- cat /etc/credentials/credentials.txt 2>/dev/null || echo "")
if echo "$CONTENT" | grep -q "username=admin" && echo "$CONTENT" | grep -q "password=s3cure!"; then
  echo "  PASS: Mounted credentials.txt has correct content"
  ((PASS++))
else
  echo "  FAIL: credentials.txt content is '$CONTENT' (expected: username=admin and password=s3cure!)"
  ((FAIL++))
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
