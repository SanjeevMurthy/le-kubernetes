#!/bin/bash
# Q29 RBAC: verify. Least privilege is two claims, not one: the permissions that
# must be there, and the permissions that must be gone. Both are graded.
source "$(dirname "$0")/../../lib/checks.sh"
source "$(dirname "$0")/../../lib/env.sh"

NS=rbac-lab
SA="system:serviceaccount:$NS:reporter"

echo "Checking anonymous access was removed..."
# go-template rather than jsonpath: a filter over a possibly absent subjects
# list is fragile, and there is no jq in the exam.
ANON=$(kubectl get clusterrolebinding -o go-template='{{range .items}}{{$n := .metadata.name}}{{if .subjects}}{{range .subjects}}{{if eq .name "system:anonymous"}}{{$n}}{{" "}}{{end}}{{end}}{{end}}{{end}}' 2>/dev/null)
if [[ -z "$(echo "$ANON" | tr -d '[:space:]')" ]]; then
  echo "  PASS: no ClusterRoleBinding has system:anonymous as a subject"; PASS=$((PASS + 1))
else
  echo "  FAIL: system:anonymous is still bound by: $ANON"; FAIL=$((FAIL + 1))
fi
check_not "clusterrolebinding/anon-viewer is gone" kubectl get clusterrolebinding anon-viewer

echo "Checking the ServiceAccount lost cluster-admin..."
check "serviceaccount $NS/reporter still exists" kubectl -n "$NS" get serviceaccount reporter
check_not "clusterrolebinding/reporter-admin is gone" kubectl get clusterrolebinding reporter-admin
CRB=$(kubectl get clusterrolebinding -o go-template='{{range .items}}{{$n := .metadata.name}}{{if .subjects}}{{range .subjects}}{{if eq .kind "ServiceAccount"}}{{if eq .name "reporter"}}{{$n}}{{" "}}{{end}}{{end}}{{end}}{{end}}{{end}}' 2>/dev/null)
if [[ -z "$(echo "$CRB" | tr -d '[:space:]')" ]]; then
  echo "  PASS: reporter has no cluster-scoped binding at all"; PASS=$((PASS + 1))
else
  echo "  FAIL: reporter is still bound cluster-wide by: $CRB"; FAIL=$((FAIL + 1))
fi

echo "Checking the grant is namespaced..."
check "a Role exists in $NS" bash -c "kubectl -n $NS get role -o name | grep -q ."
check "a RoleBinding exists in $NS" bash -c "kubectl -n $NS get rolebinding -o name | grep -q ."

# can_i <label> <expected yes|no> <verb> <resource> [-n namespace ...]
can_i() {
  local label="$1" expected="$2" verb="$3" res="$4"; shift 4
  local got
  got=$(kubectl auth can-i "$verb" "$res" --as="$SA" "$@" 2>/dev/null)
  if [[ "$got" == "$expected" ]]; then
    echo "  PASS: $label ($got)"; PASS=$((PASS + 1))
  else
    echo "  FAIL: $label (expected '$expected', got '${got:-no answer}')"; FAIL=$((FAIL + 1))
  fi
}

echo "Checking what reporter CAN do..."
can_i "can get pods in $NS"     yes get  pods     -n "$NS"
can_i "can list pods in $NS"    yes list pods     -n "$NS"
can_i "can list services in $NS" yes list services -n "$NS"
can_i "can get services in $NS"  yes get  services -n "$NS"

echo "Checking what reporter CANNOT do..."
can_i "cannot delete pods in $NS" no delete pods    -n "$NS"
can_i "cannot get secrets in $NS" no get    secrets -n "$NS"
can_i "cannot get nodes"          no get    nodes
can_i "cannot list pods in kube-system" no list pods -n kube-system
can_i "is not cluster-admin"      no '*'    '*'

summary
