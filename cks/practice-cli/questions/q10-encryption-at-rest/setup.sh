#!/bin/bash
# Q10 encryption at rest: no provider config on the apiserver, one plaintext secret in etcd.
set -e
source "$(dirname "$0")/../../lib/env.sh"
require_node_root
require_tool kubectl
require_tool etcdctl
backup_file "$KAS_MANIFEST" q10
if grep -q -- '--encryption-provider-config' "$KAS_MANIFEST"; then
  echo "Removing a leftover --encryption-provider-config flag from the API server..."
  sed -i '/--encryption-provider-config/d' "$KAS_MANIFEST"
  wait_apiserver
fi
rm -rf /etc/kubernetes/enc
kubectl create namespace enc-lab >/dev/null 2>&1 || true
kubectl -n enc-lab delete secret pre-existing --ignore-not-found >/dev/null 2>&1 || true
kubectl -n enc-lab create secret generic pre-existing --from-literal=password=cks-plaintext >/dev/null
echo "Setup complete:"
echo "  - kube-apiserver ($KAS_MANIFEST) has no --encryption-provider-config flag"
echo "  - /etc/kubernetes/enc does not exist yet; the EncryptionConfiguration goes in /etc/kubernetes/enc/enc.yaml"
echo "  - namespace enc-lab holds secret 'pre-existing' (key 'password'), written to etcd in the clear"
echo "  - etcd client certs: /etc/kubernetes/pki/etcd/{ca.crt,server.crt,server.key}"
