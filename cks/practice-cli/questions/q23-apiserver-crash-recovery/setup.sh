#!/bin/bash
# Q23 apiserver crash recovery: rename one kube-apiserver flag so the static pod
# cannot start, then leave the cluster in that state for diagnosis.
set -e
source "$(dirname "$0")/../../lib/env.sh"
require_node_root

[[ -f "$KAS_MANIFEST" ]] || { echo "missing $KAS_MANIFEST. Run this on the control-plane node."; exit 1; }

backup_file "$KAS_MANIFEST" q23

if grep -q -- '--authorization-modes=' "$KAS_MANIFEST"; then
  echo "The manifest already carries the broken flag; leaving it as it is."
elif grep -q -- '--authorization-mode=' "$KAS_MANIFEST"; then
  MODE=$(grep -oE -- '--authorization-mode=[^ ]*' "$KAS_MANIFEST" | head -1 | cut -d= -f2)
  echo "$MODE" > "$CKS_STATE_DIR/q23.mode"
  # Plural instead of singular. The binary parses its arguments before it does
  # anything else, so it exits immediately with "unknown flag".
  sed -i 's|--authorization-mode=|--authorization-modes=|' "$KAS_MANIFEST"
else
  echo "no --authorization-mode flag found in $KAS_MANIFEST; refusing to guess what to break"
  exit 1
fi

echo "Waiting for the API server to go down (up to 60 seconds)..."
down=0
for i in $(seq 1 30); do
  if curl -sk --max-time 2 https://127.0.0.1:6443/readyz 2>/dev/null | grep -q ok; then
    sleep 2
  else
    down=1
    break
  fi
done

echo "Setup complete on node $(hostname):"
echo "  Manifest:       $KAS_MANIFEST"
echo "  Seeded fault:   --authorization-mode was renamed to --authorization-modes"
echo "  Original value: $(cat "$CKS_STATE_DIR/q23.mode" 2>/dev/null || echo 'Node,RBAC')"
if [[ "$down" -eq 1 ]]; then
  echo "  State:          the API server is down and kubectl no longer answers"
else
  echo "  State:          the API server is still answering. The kubelet rescans the"
  echo "                  manifest directory about every 20 seconds, so give it a moment."
fi
echo "  Diagnose with crictl and the kubelet journal, then repair the manifest."
