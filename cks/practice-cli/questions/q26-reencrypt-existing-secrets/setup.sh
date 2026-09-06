#!/bin/bash
# Q26 re-encryption: leave the cluster with a WORKING encryption configuration
# holding a single key, key1, and three Secrets already encrypted under it.
# Adding key2 and re-encrypting is the task, so setup must not do either.
set -e
source "$(dirname "$0")/../../lib/env.sh"
require_node_root
require_tool kubectl
require_tool etcdctl
[[ -f "$KAS_MANIFEST" ]] || { echo "missing $KAS_MANIFEST — run this on the control-plane node"; exit 1; }

NS=enc-lab
ENC_DIR=/etc/kubernetes/enc
ENC="$ENC_DIR/enc.yaml"
KEYFILE="$CKS_STATE_DIR/q26.key1"
TMP=/etc/kubernetes/.kube-apiserver.yaml.q26

backup_file "$KAS_MANIFEST" q26
mkdir -p "$ENC_DIR"

# Reuse whatever key1 material is already in play. Generating a fresh key1 on
# every run would make Secrets written by an earlier run unreadable.
KEY1=""
if [[ -f "$ENC" ]]; then
  KEY1=$(awk '
    { l = $0
      sub(/^[[:space:]]*-?[[:space:]]*/, "", l)
      if (l ~ /^name:[[:space:]]*key1[[:space:]]*$/) { f = 1; next }
      if (f && l ~ /^secret:/) { sub(/^secret:[[:space:]]*/, "", l); print l; exit }
    }' "$ENC")
fi
if [[ -z "$KEY1" && -f "$KEYFILE" ]]; then KEY1=$(tr -d ' \r\n' < "$KEYFILE"); fi
if [[ -z "$KEY1" ]]; then KEY1=$(head -c 32 /dev/urandom | base64 | tr -d '\n'); fi
printf '%s\n' "$KEY1" > "$KEYFILE"
chmod 0600 "$KEYFILE"

DESIRED=$(cat <<EOF
apiVersion: apiserver.config.k8s.io/v1
kind: EncryptionConfiguration
resources:
  - resources:
      - secrets
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: $KEY1
      - identity: {}
EOF
)

CHANGED=0

# 1. The configuration file: exactly one key, key1, then identity.
if [[ "$(cat "$ENC" 2>/dev/null)" != "$DESIRED" ]]; then
  printf '%s\n' "$DESIRED" > "$ENC"
  chmod 0600 "$ENC"
  CHANGED=1
fi

# 2. The flag on the API server.
if ! grep -q -- "--encryption-provider-config=$ENC" "$KAS_MANIFEST"; then
  if grep -q -- '--encryption-provider-config=' "$KAS_MANIFEST"; then
    sed -i -E "s|- --encryption-provider-config=.*|- --encryption-provider-config=$ENC|" "$KAS_MANIFEST"
  else
    sed -i -E "s|^( *)- kube-apiserver\$|\\1- kube-apiserver\\n\\1- --encryption-provider-config=$ENC|" "$KAS_MANIFEST"
  fi
  CHANGED=1
fi

# 3. The volumeMount, so the container can read the file.
if ! grep -q "mountPath: $ENC_DIR" "$KAS_MANIFEST"; then
  awk -v d="$ENC_DIR" '
    /^[[:space:]]*volumeMounts:[[:space:]]*$/ && !m {
      print
      print "    - mountPath: " d
      print "      name: enc"
      print "      readOnly: true"
      m = 1; next
    }
    { print }' "$KAS_MANIFEST" > "$TMP" && mv "$TMP" "$KAS_MANIFEST"
  CHANGED=1
fi

# 4. The hostPath volume behind that mount.
if ! grep -q "path: $ENC_DIR" "$KAS_MANIFEST"; then
  awk -v d="$ENC_DIR" '
    /^[[:space:]]*volumes:[[:space:]]*$/ && !v {
      print
      print "  - hostPath:"
      print "      path: " d
      print "      type: DirectoryOrCreate"
      print "    name: enc"
      v = 1; next
    }
    { print }' "$KAS_MANIFEST" > "$TMP" && mv "$TMP" "$KAS_MANIFEST"
  CHANGED=1
fi

# The API server reads the EncryptionConfiguration once at start, so a change to
# the file alone is not enough. Take the manifest out of the watched directory
# and put it straight back to force the static pod to be recreated.
if [[ $CHANGED -eq 1 ]]; then
  echo "Loading the encryption configuration into kube-apiserver (this takes up to a minute)..."
  mv "$KAS_MANIFEST" "$TMP"
  sleep 8
  mv "$TMP" "$KAS_MANIFEST"
  wait_apiserver
fi

# 5. Three Secrets, written after encryption was live, so etcd holds them under key1.
kubectl create namespace "$NS" >/dev/null 2>&1 || true
for s in s1 s2 s3; do
  kubectl -n "$NS" delete secret "$s" --ignore-not-found >/dev/null 2>&1 || true
  kubectl -n "$NS" create secret generic "$s" --from-literal=password="cks-$s-value" >/dev/null
done

etcd_raw() {
  ETCDCTL_API=3 etcdctl \
    --cacert=/etc/kubernetes/pki/etcd/ca.crt \
    --cert=/etc/kubernetes/pki/etcd/server.crt \
    --key=/etc/kubernetes/pki/etcd/server.key \
    get "$1" 2>/dev/null | head -c 200 | tr -d '\0' | tr -c '[:print:]' '.'
}
STATE=$(etcd_raw "/registry/secrets/$NS/s1" | grep -o 'k8s:enc:aescbc:v1:key[0-9]*' | head -1)
[[ -n "$STATE" ]] || STATE="could not read the etcd prefix for $NS/s1"

echo "Setup complete on node $(hostname):"
echo "  Config:       $ENC holds one aescbc key named key1, then identity"
echo "  API server:   --encryption-provider-config=$ENC, with $ENC_DIR mounted into the pod"
echo "  Secrets:      $NS/s1, $NS/s2, $NS/s3 (key 'password')"
echo "  In etcd now:  $STATE"
echo "  etcd certs:   /etc/kubernetes/pki/etcd/{ca.crt,server.crt,server.key}"
echo "  Add key2 as the new write key, restart the API server, then re-encrypt."
