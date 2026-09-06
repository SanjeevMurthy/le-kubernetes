#!/bin/bash
# Q25 read a Secret from etcd: verify.
source "$(dirname "$0")/../../lib/checks.sh"
source "$(dirname "$0")/../../lib/env.sh"

NS=etcd-lab
DIR="$COURSE_DIR/25"
EXPECT_FILE="$CKS_STATE_DIR/q25.value"

if [[ ! -f "$EXPECT_FILE" ]]; then
  echo "  FAIL: no expected value recorded. Run setup first."
  echo ""; echo "Results: 0 passed, 1 failed"; exit 1
fi
VALUE=$(tr -d ' \r\n' < "$EXPECT_FILE")

echo "Checking the Secret was left alone..."
check "secret $NS/vault-token still exists" kubectl -n "$NS" get secret vault-token
LIVE=$(kjp secret vault-token "$NS" '{.data.token}' | base64 -d 2>/dev/null)
check_eq "the live Secret still holds the value setup wrote" "$VALUE" "$LIVE"

echo "Checking the etcd deliverable..."
check "$DIR/etcd.txt exists" test -s "$DIR/etcd.txt"
check_file_has "etcd.txt holds the plain-text token read from etcd" "$VALUE" "$DIR/etcd.txt"

echo "Checking the kubectl deliverable..."
check "$DIR/kubectl.txt exists" test -s "$DIR/kubectl.txt"
check_file_has "kubectl.txt holds the same value read through the API" "$VALUE" "$DIR/kubectl.txt"

summary
