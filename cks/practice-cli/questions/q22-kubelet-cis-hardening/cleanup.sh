#!/bin/bash
# Q22 kubelet CIS hardening: put the worker's kubelet configuration back and
# restart the kubelet so the node returns to its original state.
source "$(dirname "$0")/../../lib/env.sh"
CONF=/var/lib/kubelet/config.yaml
restore_file "$CONF" q22
on_worker bash -s <<'REMOTE' 2>/dev/null
CONF=/var/lib/kubelet/config.yaml
if [ -f "$CONF.q22bak" ]; then
  cp -p "$CONF.q22bak" "$CONF"
  rm -f "$CONF.q22bak"
fi
rm -f "$CONF.q22new"
systemctl restart kubelet 2>/dev/null || true
REMOTE
echo "Cleanup complete"
