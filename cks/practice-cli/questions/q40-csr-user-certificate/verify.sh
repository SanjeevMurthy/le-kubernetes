#!/bin/bash
# Q40 CSR: verify. The certificate is only half the answer; the other half is
# that the identity it carries is granted exactly what the task asked for.
source "$(dirname "$0")/../../lib/checks.sh"
source "$(dirname "$0")/../../lib/env.sh"

NS=csr-lab
DIR="$COURSE_DIR/40"
CRT="$DIR/jane.crt"

echo "Checking the CertificateSigningRequest..."
check "certificatesigningrequest/jane exists" kubectl get csr jane
check_eq "the signer is the API server client signer" \
  "kubernetes.io/kube-apiserver-client" "$(kjp csr jane '' '{.spec.signerName}')"
check_contains "usages include client auth" "client auth" "$(kjp csr jane '' '{.spec.usages[*]}')"
check_contains "the request carries the Approved condition" Approved \
  "$(kjp csr jane '' '{.status.conditions[*].type}')"
check "the request has a non-empty .status.certificate" \
  test -n "$(kjp csr jane '' '{.status.certificate}')"

echo "Checking the extracted certificate..."
check "$CRT exists and is not empty" test -s "$CRT"
# Precondition: the file has to parse before its subject means anything. A
# truncated or base64-still-encoded file would otherwise fail the CN test with
# a misleading reason.
check "$CRT parses as an x509 certificate" openssl x509 -in "$CRT" -noout
SUBJ=$(openssl x509 -in "$CRT" -noout -subject 2>/dev/null)
if [[ "$SUBJ" =~ CN[[:space:]]*=[[:space:]]*jane ]]; then
  echo "  PASS: the certificate subject names jane ($SUBJ)"; PASS=$((PASS + 1))
else
  echo "  FAIL: expected a subject with CN = jane, got '${SUBJ:-<unreadable>}'"; FAIL=$((FAIL + 1))
fi

echo "Checking the grant is namespaced..."
check "a Role exists in $NS" bash -c "kubectl -n $NS get role -o name | grep -q ."
RBSUBJ=$(kubectl -n "$NS" get rolebinding -o go-template='{{range .items}}{{if .subjects}}{{range .subjects}}{{.kind}}{{" "}}{{.name}}{{"\n"}}{{end}}{{end}}{{end}}' 2>/dev/null)
check_contains "a RoleBinding in $NS names User jane" "User jane" "$RBSUBJ"
CRB=$(kubectl get clusterrolebinding -o go-template='{{range .items}}{{$n := .metadata.name}}{{if .subjects}}{{range .subjects}}{{if eq .name "jane"}}{{$n}}{{"\n"}}{{end}}{{end}}{{end}}{{end}}' 2>/dev/null | tr '\n' ' ')
if [[ -z "$(echo "$CRB" | tr -d '[:space:]')" ]]; then
  echo "  PASS: jane has no cluster-scoped binding"; PASS=$((PASS + 1))
else
  echo "  FAIL: jane is bound cluster-wide by: $CRB"; FAIL=$((FAIL + 1))
fi

# can_i <label> <expected yes|no> <verb> <resource> [-n namespace ...]
can_i() {
  local label="$1" expected="$2" verb="$3" res="$4"; shift 4
  local got
  got=$(kubectl auth can-i "$verb" "$res" --as jane "$@" 2>/dev/null)
  if [[ "$got" == "$expected" ]]; then
    echo "  PASS: $label ($got)"; PASS=$((PASS + 1))
  else
    echo "  FAIL: $label (expected '$expected', got '${got:-no answer}')"; FAIL=$((FAIL + 1))
  fi
}

# The yes answers come first on purpose. They prove that impersonation works at
# all, so a no below is a real refusal and not a broken query.
echo "Checking what jane CAN do..."
can_i "can list pods in $NS" yes list pods -n "$NS"
can_i "can get pods in $NS"  yes get  pods -n "$NS"

echo "Checking what jane CANNOT do..."
can_i "cannot get secrets in $NS"       no get    secrets -n "$NS"
can_i "cannot delete pods in $NS"       no delete pods    -n "$NS"
can_i "cannot list pods in kube-system" no list   pods    -n kube-system
can_i "cannot get nodes"                no get    nodes

summary
