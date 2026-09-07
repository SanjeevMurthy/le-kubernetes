#!/bin/bash
# Q4 RBAC least privilege: verify. Graded on effective permissions rather than on
# the shape of the Role, because several correct answers exist.
source "$(dirname "$0")/../../lib/checks.sh"
source "$(dirname "$0")/../../lib/env.sh"

SA=system:serviceaccount:build:ci
NS=build

can() {   # can "label" expected verb resource
  check_eq "$1" "$2" "$(kubectl auth can-i "$3" "$4" --as="$SA" -n "$NS" 2>/dev/null)"
}

echo "Checking the ServiceAccount still exists (control)..."
check "ServiceAccount ci exists in $NS" kubectl get serviceaccount ci -n "$NS"

echo "Checking what build:ci can do..."
can "can list pods"      yes list   pods
can "can get pods/log"   yes get    pods/log

echo "Checking what it must not be able to do..."
can "cannot delete pods"      no delete pods
can "cannot get secrets"      no get    secrets
can "is no longer cluster-admin" no '*' '*'

summary
