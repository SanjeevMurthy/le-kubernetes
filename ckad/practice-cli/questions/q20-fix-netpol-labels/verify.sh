#!/bin/bash
# Q20 — Fix NetworkPolicy Labels: Verify
PASS=0; FAIL=0

echo "Checking pod 'frontend' has label role=frontend..."
FRONTEND_ROLE=$(kubectl get pod frontend -n network-demo -o jsonpath='{.metadata.labels.role}' 2>/dev/null)
if [[ "$FRONTEND_ROLE" == "frontend" ]]; then
  echo "  PASS: Pod frontend has label role=frontend"
  ((PASS++))
else
  echo "  FAIL: Pod frontend role label is '$FRONTEND_ROLE', expected 'frontend'"
  ((FAIL++))
fi

echo "Checking pod 'backend' has label role=backend..."
BACKEND_ROLE=$(kubectl get pod backend -n network-demo -o jsonpath='{.metadata.labels.role}' 2>/dev/null)
if [[ "$BACKEND_ROLE" == "backend" ]]; then
  echo "  PASS: Pod backend has label role=backend"
  ((PASS++))
else
  echo "  FAIL: Pod backend role label is '$BACKEND_ROLE', expected 'backend'"
  ((FAIL++))
fi

echo "Checking pod 'database' has label role=db..."
DB_ROLE=$(kubectl get pod database -n network-demo -o jsonpath='{.metadata.labels.role}' 2>/dev/null)
if [[ "$DB_ROLE" == "db" ]]; then
  echo "  PASS: Pod database has label role=db"
  ((PASS++))
else
  echo "  FAIL: Pod database role label is '$DB_ROLE', expected 'db'"
  ((FAIL++))
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
