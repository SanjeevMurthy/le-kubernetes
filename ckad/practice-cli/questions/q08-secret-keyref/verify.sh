#!/bin/bash
# Q8 — Secret KeyRef Migration: Verify
PASS=0; FAIL=0

echo "Checking Secret db-credentials exists..."
if kubectl get secret db-credentials &>/dev/null; then
  echo "  PASS: Secret db-credentials exists"
  ((PASS++))
else
  echo "  FAIL: Secret db-credentials not found"
  ((FAIL++))
fi

echo "Checking Secret has key DB_USER..."
DB_USER_VAL=$(kubectl get secret db-credentials -o jsonpath='{.data.DB_USER}' 2>/dev/null | base64 -d 2>/dev/null || echo "")
if [[ "$DB_USER_VAL" == "admin" ]]; then
  echo "  PASS: Secret key DB_USER has correct value"
  ((PASS++))
else
  echo "  FAIL: Secret key DB_USER value is '$DB_USER_VAL' (expected: admin)"
  ((FAIL++))
fi

echo "Checking Secret has key DB_PASS..."
DB_PASS_VAL=$(kubectl get secret db-credentials -o jsonpath='{.data.DB_PASS}' 2>/dev/null | base64 -d 2>/dev/null || echo "")
if [[ "$DB_PASS_VAL" == "Secret123!" ]]; then
  echo "  PASS: Secret key DB_PASS has correct value"
  ((PASS++))
else
  echo "  FAIL: Secret key DB_PASS value is '$DB_PASS_VAL' (expected: Secret123!)"
  ((FAIL++))
fi

echo "Checking deployment api-server uses secretKeyRef for DB_USER..."
USER_REF=$(kubectl get deployment api-server -o json 2>/dev/null | python3 -c "
import sys, json
spec = json.load(sys.stdin)
containers = spec['spec']['template']['spec']['containers']
for c in containers:
    for e in c.get('env', []):
        if e.get('name') == 'DB_USER':
            ref = e.get('valueFrom', {}).get('secretKeyRef', {})
            if ref.get('name') == 'db-credentials' and ref.get('key') == 'DB_USER':
                print('ok')
                sys.exit(0)
print('missing')
" 2>/dev/null || echo "error")
if [[ "$USER_REF" == "ok" ]]; then
  echo "  PASS: DB_USER uses secretKeyRef from db-credentials"
  ((PASS++))
else
  echo "  FAIL: DB_USER does not use secretKeyRef from db-credentials (expected: secretKeyRef)"
  ((FAIL++))
fi

echo "Checking deployment api-server uses secretKeyRef for DB_PASS..."
PASS_REF=$(kubectl get deployment api-server -o json 2>/dev/null | python3 -c "
import sys, json
spec = json.load(sys.stdin)
containers = spec['spec']['template']['spec']['containers']
for c in containers:
    for e in c.get('env', []):
        if e.get('name') == 'DB_PASS':
            ref = e.get('valueFrom', {}).get('secretKeyRef', {})
            if ref.get('name') == 'db-credentials' and ref.get('key') == 'DB_PASS':
                print('ok')
                sys.exit(0)
print('missing')
" 2>/dev/null || echo "error")
if [[ "$PASS_REF" == "ok" ]]; then
  echo "  PASS: DB_PASS uses secretKeyRef from db-credentials"
  ((PASS++))
else
  echo "  FAIL: DB_PASS does not use secretKeyRef from db-credentials (expected: secretKeyRef)"
  ((FAIL++))
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
