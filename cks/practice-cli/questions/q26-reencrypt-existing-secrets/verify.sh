#!/bin/bash
# Q26 re-encryption: verify. The configuration alone proves nothing, because a
# correct-looking enc.yaml still leaves old Secrets encrypted under the old key.
# The graded fact is the prefix of the value that is actually stored in etcd.
source "$(dirname "$0")/../../lib/checks.sh"
source "$(dirname "$0")/../../lib/env.sh"

NS=enc-lab
ENC=$(grep -o -- '--encryption-provider-config=[^[:space:]]*' "$KAS_MANIFEST" 2>/dev/null | head -1 | sed 's/.*=//')
[[ -n "$ENC" ]] || ENC=/etc/kubernetes/enc/enc.yaml

echo "Checking the API server is still wired to $ENC..."
check_file_has "apiserver has --encryption-provider-config" '--encryption-provider-config=' "$KAS_MANIFEST"
check_file_has "the config directory is mounted into the pod" 'mountPath: */etc/kubernetes/enc' "$KAS_MANIFEST"
check "apiserver is ready" bash -c 'curl -sk --max-time 5 https://127.0.0.1:6443/readyz | grep -q ok'

echo "Checking the key order in $ENC..."
check_file_has "a key named key2 was added" 'name: *"?key2"?' "$ENC"
check_file_has "key1 is still present for reading" 'name: *"?key1"?' "$ENC"

k2=$(grep -nE 'name: *"?key2"?' "$ENC" 2>/dev/null | head -1 | cut -d: -f1)
k1=$(grep -nE 'name: *"?key1"?' "$ENC" 2>/dev/null | head -1 | cut -d: -f1)
if [[ -n "$k2" && -n "$k1" && "$k2" -lt "$k1" ]]; then
  echo "  PASS: key2 is listed before key1, so it is the write key (lines $k2 and $k1)"; PASS=$((PASS + 1))
else
  echo "  FAIL: key2 must be the first key in the aescbc provider (key2 at line '${k2:-none}', key1 at line '${k1:-none}')"; FAIL=$((FAIL + 1))
fi

a=$(grep -n 'aescbc' "$ENC" 2>/dev/null | head -1 | cut -d: -f1)
i=$(grep -n 'identity' "$ENC" 2>/dev/null | head -1 | cut -d: -f1)
if [[ -n "$a" && -n "$i" && "$a" -lt "$i" ]]; then
  echo "  PASS: aescbc is still listed before identity (lines $a and $i)"; PASS=$((PASS + 1))
else
  echo "  FAIL: $ENC must keep identity as the last provider (aescbc at line '${a:-none}', identity at line '${i:-none}')"; FAIL=$((FAIL + 1))
fi

echo "Checking the Secrets are still readable through the API..."
for s in s1 s2 s3; do
  check "secret $NS/$s is readable" kubectl -n "$NS" get secret "$s"
done

etcd_raw() {
  ETCDCTL_API=3 etcdctl \
    --cacert=/etc/kubernetes/pki/etcd/ca.crt \
    --cert=/etc/kubernetes/pki/etcd/server.crt \
    --key=/etc/kubernetes/pki/etcd/server.key \
    get "$1" 2>/dev/null | head -c 200 | tr -d '\0' | tr -c '[:print:]' '.'
}

echo "Reading the raw etcd values (effect test: only re-encryption changes these)..."
for s in s1 s2 s3; do
  RAW=$(etcd_raw "/registry/secrets/$NS/$s")
  if [[ -z "$RAW" ]]; then
    echo "  FAIL: etcdctl returned nothing for /registry/secrets/$NS/$s (is etcd reachable?)"; FAIL=$((FAIL + 1))
  elif echo "$RAW" | grep -q 'k8s:enc:aescbc:v1:key2'; then
    echo "  PASS: $NS/$s is stored under key2"; PASS=$((PASS + 1))
  else
    got=$(echo "$RAW" | grep -o 'k8s:enc:aescbc:v1:key[0-9]*' | head -1)
    echo "  FAIL: $NS/$s is stored under '${got:-no aescbc prefix at all}', not key2; re-encrypt with: kubectl -n $NS get secrets -o json | kubectl replace -f -"; FAIL=$((FAIL + 1))
  fi
done

summary
