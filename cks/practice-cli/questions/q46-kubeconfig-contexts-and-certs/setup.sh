#!/bin/bash
# Q46 kubeconfig: a multi-cluster kubeconfig whose green-restricted user carries
# a real client certificate, so decoding it produces a real subject rather than
# a string the question planted in plain sight.
set -e
source "$(dirname "$0")/../../lib/env.sh"
require_tool openssl

DIR=$(course_dir 46)
KC="$DIR/kubeconfig"

rm -f "$DIR/contexts" "$DIR/current" "$DIR/cert-cn" "$DIR/cert-group"

CN="restricted-7261"
ORG="incident-reviewers"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

openssl req -x509 -newkey rsa:2048 -nodes -days 3650 \
  -keyout "$TMP/green.key" -out "$TMP/green.crt" \
  -subj "/CN=$CN/O=$ORG" >/dev/null 2>&1

# openssl's own base64 rather than base64(1): -A gives one unwrapped line on
# every platform, where the coreutils spelling (-w0) does not exist on macOS.
CRT_B64=$(openssl base64 -A -in "$TMP/green.crt")
KEY_B64=$(openssl base64 -A -in "$TMP/green.key")
CA_B64=$(openssl base64 -A -in "$TMP/green.crt")

cat > "$KC" <<EOF
apiVersion: v1
kind: Config
current-context: green-cluster-restricted
preferences: {}
clusters:
- name: blue
  cluster:
    server: https://10.0.1.10:6443
    certificate-authority-data: $CA_B64
- name: green
  cluster:
    server: https://10.0.2.10:6443
    certificate-authority-data: $CA_B64
- name: orange
  cluster:
    server: https://10.0.3.10:6443
    certificate-authority-data: $CA_B64
contexts:
- name: blue-cluster-admin
  context:
    cluster: blue
    user: blue-admin
- name: green-cluster-restricted
  context:
    cluster: green
    namespace: incident
    user: green-restricted
- name: orange-cluster-audit
  context:
    cluster: orange
    user: orange-audit
users:
- name: blue-admin
  user:
    token: blue-admin-token-lab-only
- name: green-restricted
  user:
    client-certificate-data: $CRT_B64
    client-key-data: $KEY_B64
- name: orange-audit
  user:
    token: orange-audit-token-lab-only
EOF
chmod 600 "$KC"

# The verifier compares against the subject that was actually issued, so record
# it outside the working directory.
mkdir -p "$CKS_STATE_DIR/backup/q46"
printf '%s\n%s\n' "$CN" "$ORG" > "$CKS_STATE_DIR/backup/q46/expected"

echo "Setup complete."
echo "  Kubeconfig:  $KC   (three clusters, three contexts)"
echo "  Deliverables in $DIR:"
echo "    contexts     every context name, one per line"
echo "    current      the current context of that file"
echo "    cert-cn      the Common Name of green-restricted's certificate"
echo "    cert-group   its Organization"
echo "  None of these clusters exists. Do not switch your own context."
