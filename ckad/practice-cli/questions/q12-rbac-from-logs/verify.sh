#!/bin/bash
# Q12 — RBAC from Pod Logs: Verify
PASS=0; FAIL=0

echo "Checking ServiceAccount log-sa exists in audit namespace..."
if kubectl get serviceaccount log-sa -n audit &>/dev/null; then
  echo "  PASS: ServiceAccount log-sa exists"
  ((PASS++))
else
  echo "  FAIL: ServiceAccount log-sa not found in audit namespace"
  ((FAIL++))
fi

echo "Checking Role exists in audit namespace with get,list,watch on pods..."
ROLE_NAME=$(kubectl get roles -n audit -o json 2>/dev/null | python3 -c "
import sys, json
data = json.load(sys.stdin)
required = {'get', 'list', 'watch'}
for r in data.get('items', []):
    for rule in r.get('rules', []):
        resources = set(rule.get('resources', []))
        verbs = set(rule.get('verbs', []))
        if 'pods' in resources and required.issubset(verbs):
            print(r['metadata']['name'])
            sys.exit(0)
print('')
" 2>/dev/null || echo "")
if [[ -n "$ROLE_NAME" ]]; then
  echo "  PASS: Role '$ROLE_NAME' grants get,list,watch on pods"
  ((PASS++))
else
  echo "  FAIL: No Role found in audit namespace granting get,list,watch on pods (expected: Role with pods get,list,watch)"
  ((FAIL++))
fi

echo "Checking RoleBinding exists binding role to log-sa..."
BINDING_OK=$(kubectl get rolebindings -n audit -o json 2>/dev/null | python3 -c "
import sys, json
data = json.load(sys.stdin)
for rb in data.get('items', []):
    subjects = rb.get('subjects', [])
    for s in subjects:
        if s.get('kind') == 'ServiceAccount' and s.get('name') == 'log-sa':
            print('found')
            sys.exit(0)
print('missing')
" 2>/dev/null || echo "error")
if [[ "$BINDING_OK" == "found" ]]; then
  echo "  PASS: RoleBinding binds to log-sa"
  ((PASS++))
else
  echo "  FAIL: No RoleBinding found binding to log-sa (expected: RoleBinding for log-sa)"
  ((FAIL++))
fi

echo "Checking Pod log-collector uses serviceAccount log-sa..."
SA_NAME=$(kubectl get pod log-collector -n audit -o jsonpath='{.spec.serviceAccountName}' 2>/dev/null || echo "")
if [[ "$SA_NAME" == "log-sa" ]]; then
  echo "  PASS: Pod log-collector uses serviceAccount log-sa"
  ((PASS++))
else
  echo "  FAIL: Pod serviceAccountName is '$SA_NAME' (expected: log-sa)"
  ((FAIL++))
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
