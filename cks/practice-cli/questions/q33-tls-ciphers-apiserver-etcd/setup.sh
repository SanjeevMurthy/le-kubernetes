#!/bin/bash
# Q33 TLS hardening: strip any TLS version or cipher flags from both control
# plane static pods so the candidate starts from the Go defaults.
set -e
source "$(dirname "$0")/../../lib/env.sh"
require_node_root
require_tool kubectl

ETCD_MANIFEST=/etc/kubernetes/manifests/etcd.yaml
[[ -f "$KAS_MANIFEST" ]] || { echo "missing $KAS_MANIFEST; run this on the control-plane node"; exit 1; }
[[ -f "$ETCD_MANIFEST" ]] || { echo "missing $ETCD_MANIFEST; this cluster does not run a stacked etcd"; exit 1; }

backup_file "$KAS_MANIFEST" q33
backup_file "$ETCD_MANIFEST" q33

CHANGED=0
if grep -qE -- '--tls-min-version=|--tls-cipher-suites=' "$KAS_MANIFEST"; then
  sed -i '/--tls-min-version=/d; /--tls-cipher-suites=/d' "$KAS_MANIFEST"
  CHANGED=1
fi
if grep -q -- '--cipher-suites=' "$ETCD_MANIFEST"; then
  sed -i '/--cipher-suites=/d' "$ETCD_MANIFEST"
  CHANGED=1
fi

if [[ "$CHANGED" -eq 1 ]]; then
  echo "Removed the existing TLS flags; waiting for the control plane to come back..."
  wait_apiserver
fi

command -v openssl >/dev/null 2>&1 || echo "warning: openssl is not on this node, and the effect test needs it (apt-get install -y openssl)"

TLS12="unknown"
if command -v openssl >/dev/null 2>&1; then
  if echo | timeout 10 openssl s_client -connect 127.0.0.1:6443 -tls1_2 2>&1 | grep -q 'Cipher *is *TLS_'; then
    TLS12="accepted (this is what has to change)"
  else
    TLS12="already refused"
  fi
fi

echo "Setup complete on node $(hostname):"
echo "  API server manifest: $KAS_MANIFEST   (no --tls-min-version, no --tls-cipher-suites)"
echo "  etcd manifest:       $ETCD_MANIFEST  (no --cipher-suites)"
echo "  TLS 1.2 on 127.0.0.1:6443 right now: $TLS12"
echo "  Both are static pods, so an edit restarts them. Change one file at a time."
echo "  Watch a restart with: crictl ps | grep -E 'kube-apiserver|etcd'"
