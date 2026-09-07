#!/bin/bash
# Q2 kube-bench: seed two real CIS failures on this control-plane node,
# 1.2.1 (apiserver accepts anonymous requests) and 4.2.4 (kubelet read-only port).
set -e
source "$(dirname "$0")/../../lib/env.sh"
require_node_root
require_tool kube-bench
KUBELET_CONF=/var/lib/kubelet/config.yaml
[[ -f "$KAS_MANIFEST" ]] || { echo "missing $KAS_MANIFEST — run this on the control-plane node"; exit 1; }
[[ -f "$KUBELET_CONF" ]] || { echo "missing $KUBELET_CONF — run this on a kubeadm node"; exit 1; }

backup_file "$KAS_MANIFEST" q02
backup_file "$KUBELET_CONF" q02

# CIS 1.2.1 — turn anonymous auth back on in the apiserver static pod manifest.
if grep -q -- '- --anonymous-auth=' "$KAS_MANIFEST"; then
  sed -i -E 's|- --anonymous-auth=.*|- --anonymous-auth=true|' "$KAS_MANIFEST"
else
  sed -i -E 's|^( *)- kube-apiserver$|\1- kube-apiserver\n\1- --anonymous-auth=true|' "$KAS_MANIFEST"
fi
wait_apiserver

# CIS 4.2.4 — expose the kubelet's unauthenticated read-only port.
if grep -Eq '^readOnlyPort:' "$KUBELET_CONF"; then
  sed -i -E 's|^readOnlyPort:.*|readOnlyPort: 10255|' "$KUBELET_CONF"
else
  printf 'readOnlyPort: 10255\n' >> "$KUBELET_CONF"
fi
systemctl restart kubelet
for i in $(seq 1 15); do
  if curl -s --max-time 2 http://127.0.0.1:10255/pods >/dev/null 2>&1; then break; fi
  sleep 2
done

echo "Setup complete on node $(hostname):"
echo "  $KAS_MANIFEST   now has --anonymous-auth=true   -> CIS 1.2.1 FAIL"
echo "  $KUBELET_CONF   now has readOnlyPort: 10255     -> CIS 4.2.4 FAIL"
echo "  the unauthenticated read-only port answers today:"
echo "    curl -s --max-time 3 http://127.0.0.1:10255/pods"
echo "  Fix CIS 1.2.1 and 4.2.4, then re-check with:"
echo "    kube-bench run --targets node --check 4.2.4"
