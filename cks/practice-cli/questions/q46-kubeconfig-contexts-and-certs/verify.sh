#!/bin/bash
# Q46 kubeconfig: verify. The context list is compared as a set, because the
# task asked for the names and not for an order. The subject is compared against
# what the setup actually issued, so a candidate who guesses cannot pass.
source "$(dirname "$0")/../../lib/checks.sh"
source "$(dirname "$0")/../../lib/env.sh"

DIR="$COURSE_DIR/46"
KC="$DIR/kubeconfig"
EXPECTED_FILE="$CKS_STATE_DIR/backup/q46/expected"

if [[ ! -s "$EXPECTED_FILE" ]]; then
  echo "  FAIL: this question has not been set up (run [S] first)"
  echo ""
  echo "Results: 0 passed, 1 failed"
  exit 1
fi
WANT_CN=$(sed -n 1p "$EXPECTED_FILE")
WANT_ORG=$(sed -n 2p "$EXPECTED_FILE")

echo "Checking the kubeconfig was left intact..."
# Precondition. Every answer below is read out of this file, so if it has been
# edited the checks are grading the candidate's edit rather than the task.
check "$KC still exists" test -s "$KC"
check_eq "it still holds three contexts" 3 \
  "$(kubectl --kubeconfig "$KC" config get-contexts -o name 2>/dev/null | grep -c .)"

echo "Checking the context list..."
check "$DIR/contexts exists and is not empty" test -s "$DIR/contexts"
GOT=$(sort -u "$DIR/contexts" 2>/dev/null | grep -c .)
check_eq "it names three contexts" 3 "${GOT:-0}"
for c in blue-cluster-admin green-cluster-restricted orange-cluster-audit; do
  check "it lists $c" grep -qx "$c" "$DIR/contexts"
done
# A candidate who dumped `config get-contexts` without -o name writes the table,
# CURRENT and CLUSTER columns included. Those lines are not context names.
# Guarded on the file existing: grep over a missing file also exits non-zero,
# which would let check_not report a pass before anything had been written.
if [[ ! -f "$DIR/contexts" ]]; then
  echo "  FAIL: it holds names only, not the get-contexts table (no such file)"; FAIL=$((FAIL + 1))
else
  check_not "it holds names only, not the get-contexts table" \
    grep -qE 'CURRENT|AUTHINFO|NAMESPACE|^\*' "$DIR/contexts"
fi

echo "Checking the current context..."
check "$DIR/current exists and is not empty" test -s "$DIR/current"
check_eq "it names the file's current context" "green-cluster-restricted" \
  "$(head -1 "$DIR/current" 2>/dev/null | tr -d '[:space:]')"

echo "Checking the decoded certificate..."
check "$DIR/cert-cn exists and is not empty" test -s "$DIR/cert-cn"
CN=$(head -1 "$DIR/cert-cn" 2>/dev/null | tr -d '[:space:]')
check_eq "cert-cn is the certificate's Common Name" "$WANT_CN" "${CN:-<empty>}"
check "$DIR/cert-group exists and is not empty" test -s "$DIR/cert-group"
ORG=$(head -1 "$DIR/cert-group" 2>/dev/null | tr -d '[:space:]')
check_eq "cert-group is the certificate's Organization" "$WANT_ORG" "${ORG:-<empty>}"

echo "Checking your own context was not disturbed..."
# The task said not to adopt this kubeconfig. Adopting it would be a real
# mistake in an exam, where the next task expects the cluster you started with.
MINE=$(kubectl config current-context 2>/dev/null)
if [[ "$MINE" == "green-cluster-restricted" ]]; then
  echo "  FAIL: your current context is now green-cluster-restricted; the handed-over kubeconfig was adopted"; FAIL=$((FAIL + 1))
else
  echo "  PASS: your own context is untouched (${MINE:-none})"; PASS=$((PASS + 1))
fi

summary
