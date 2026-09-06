#!/bin/bash
# Q26 re-encryption: cleanup.
#
# Order matters. The documented solution re-encrypts Secrets cluster-wide, so
# simply restoring an API server that has no encryption flag would leave every
# one of those Secrets as unreadable ciphertext. Put identity first, let the API
# server rewrite everything in the clear, and only then restore the manifest.
source "$(dirname "$0")/../../lib/env.sh"

ENC_DIR=/etc/kubernetes/enc
ENC="$ENC_DIR/enc.yaml"
TMP=/etc/kubernetes/.kube-apiserver.yaml.q26

if [[ -f "$ENC" ]] && grep -q -- "--encryption-provider-config=" "$KAS_MANIFEST" 2>/dev/null; then
  # Collect every key currently in the file so decryption still works.
  KEYS=$(awk '
    { l = $0
      sub(/^[[:space:]]*-?[[:space:]]*/, "", l)
      if (l ~ /^name:/)   { n = l; sub(/^name:[[:space:]]*/, "", n) }
      else if (l ~ /^secret:/ && n != "") {
        s = l; sub(/^secret:[[:space:]]*/, "", s)
        print "            - name: " n
        print "              secret: " s
        n = ""
      }
    }' "$ENC")

  if [[ -n "$KEYS" ]]; then
    {
      echo "apiVersion: apiserver.config.k8s.io/v1"
      echo "kind: EncryptionConfiguration"
      echo "resources:"
      echo "  - resources:"
      echo "      - secrets"
      echo "    providers:"
      echo "      - identity: {}"
      echo "      - aescbc:"
      echo "          keys:"
      printf '%s\n' "$KEYS"
    } > "$ENC"

    echo "Switching writes back to plain text and rewriting the Secrets..."
    mv "$KAS_MANIFEST" "$TMP" 2>/dev/null
    sleep 8
    mv "$TMP" "$KAS_MANIFEST" 2>/dev/null
    wait_apiserver
    kubectl get secrets -A -o json 2>/dev/null | kubectl replace -f - >/dev/null 2>&1 || true
  fi
fi

kubectl delete namespace enc-lab --ignore-not-found >/dev/null 2>&1
restore_file "$KAS_MANIFEST" q26
wait_apiserver
rm -rf "$ENC_DIR"
rm -f "$CKS_STATE_DIR/q26.key1"
echo "Cleanup complete"
