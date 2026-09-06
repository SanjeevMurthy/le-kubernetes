#!/bin/bash
# Q25 read a Secret from etcd: create a Secret whose value is random on every
# run, so the answer has to be found rather than remembered.
set -e
source "$(dirname "$0")/../../lib/env.sh"
require_node_root
require_tool kubectl
require_tool etcdctl

# The whole point of the question is that etcd holds the value in the clear.
# If a previous question left encryption at rest switched on, say so plainly
# instead of handing over a lab that cannot be solved.
if grep -q -- '--encryption-provider-config=' "$KAS_MANIFEST" 2>/dev/null; then
  ENCFILE=$(grep -o -- '--encryption-provider-config=[^[:space:]]*' "$KAS_MANIFEST" | head -1 | sed 's/.*=//')
  if [[ -f "$ENCFILE" ]] && grep -qE 'aescbc|aesgcm|secretbox|kms' "$ENCFILE"; then
    echo "This cluster encrypts Secrets at rest ($ENCFILE), so etcd holds ciphertext."
    echo "Run the cleanup of Q10 or Q26 first, then set this question up again."
    exit 1
  fi
fi

NS=etcd-lab
VALUE=$(LC_ALL=C tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 16)
[[ ${#VALUE} -eq 16 ]] || { echo "could not generate a 16-character value from /dev/urandom"; exit 1; }

kubectl create namespace "$NS" >/dev/null 2>&1 || true
kubectl -n "$NS" delete secret vault-token --ignore-not-found >/dev/null 2>&1 || true
kubectl -n "$NS" create secret generic vault-token --from-literal=token="$VALUE" >/dev/null

printf '%s\n' "$VALUE" > "$CKS_STATE_DIR/q25.value"
chmod 0600 "$CKS_STATE_DIR/q25.value"

DIR=$(course_dir 25)

echo "Setup complete on node $(hostname):"
echo "  Secret:       $NS/vault-token, one key 'token', value regenerated on every setup"
echo "  etcd key:     /registry/secrets/$NS/vault-token"
echo "  etcd certs:   /etc/kubernetes/pki/etcd/{ca.crt,server.crt,server.key}"
echo "  Encryption:   kube-apiserver has no --encryption-provider-config, so the value is stored in the clear"
echo "  Deliverables: $DIR/etcd.txt and $DIR/kubectl.txt"
echo "  The expected value is recorded outside the repo; there is nothing to memorise."
