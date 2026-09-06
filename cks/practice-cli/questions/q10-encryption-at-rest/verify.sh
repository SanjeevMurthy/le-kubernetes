#!/bin/bash
# Q10 encryption at rest: verify.
source "$(dirname "$0")/../../lib/checks.sh"; source "$(dirname "$0")/../../lib/env.sh"
ENC=$(grep -o -- '--encryption-provider-config=[^[:space:]]*' "$KAS_MANIFEST" 2>/dev/null | head -1 | sed 's/.*=//')
[[ -n "$ENC" ]] || ENC=/etc/kubernetes/enc/enc.yaml
echo "Checking the API server is wired to an EncryptionConfiguration..."
check_file_has "apiserver has --encryption-provider-config" '--encryption-provider-config=' "$KAS_MANIFEST"
check_file_has "the config directory is mounted into the pod" 'mountPath: */etc/kubernetes/enc' "$KAS_MANIFEST"
check_file_has "the config directory has a hostPath volume" 'path: */etc/kubernetes/enc' "$KAS_MANIFEST"
echo "Checking the provider order in $ENC..."
check_file_has "the file is an EncryptionConfiguration" 'kind: *EncryptionConfiguration' "$ENC"
check_file_has "it encrypts the resource secrets" 'resources: *(\[? *"?secrets|- *"?secrets)' "$ENC"
a=$(grep -n 'aescbc' "$ENC" 2>/dev/null | head -1 | cut -d: -f1)
i=$(grep -n 'identity' "$ENC" 2>/dev/null | head -1 | cut -d: -f1)
if [[ -n "$a" && -n "$i" && "$a" -lt "$i" ]]; then
  echo "  PASS: aescbc is listed before identity (lines $a and $i)"; PASS=$((PASS + 1))
else
  echo "  FAIL: $ENC must list the aescbc provider first and identity last (aescbc at line '${a:-none}', identity at line '${i:-none}')"; FAIL=$((FAIL + 1))
fi
check "apiserver is ready" bash -c 'curl -sk --max-time 5 https://127.0.0.1:6443/readyz | grep -q ok'
check "secret enc-lab/pre-existing is still readable through the API" kubectl -n enc-lab get secret pre-existing
echo "Reading the raw etcd value of /registry/secrets/enc-lab/pre-existing (effect test)..."
RAW=$(ETCDCTL_API=3 etcdctl \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  get /registry/secrets/enc-lab/pre-existing 2>/dev/null | head -c 200 | tr -d '\0' | tr -c '[:print:]' '.')
if [[ -z "$RAW" ]]; then
  echo "  FAIL: etcdctl returned nothing for /registry/secrets/enc-lab/pre-existing (is etcd reachable and the secret present?)"; FAIL=$((FAIL + 1))
elif echo "$RAW" | grep -q 'k8s:enc:aescbc'; then
  echo "  PASS: the value stored in etcd is encrypted (k8s:enc:aescbc prefix)"; PASS=$((PASS + 1))
else
  echo "  FAIL: the value stored in etcd is not aescbc-encrypted; re-encrypt existing Secrets with: kubectl get secrets -A -o json | kubectl replace -f -"; FAIL=$((FAIL + 1))
fi
summary
