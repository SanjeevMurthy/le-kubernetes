#!/bin/bash
# Q37 apiserver bad volume: add a volumeMounts entry that no volume backs, so the
# kubelet refuses the pod outright and the container never starts.
set -e
source "$(dirname "$0")/../../lib/env.sh"
require_node_root

[[ -f "$KAS_MANIFEST" ]] || { echo "missing $KAS_MANIFEST. Run this on the control-plane node."; exit 1; }

backup_file "$KAS_MANIFEST" q37

if grep -q 'audit-typo' "$KAS_MANIFEST"; then
  echo "The manifest already carries the broken mount; leaving it as it is."
else
  TMP=$(mktemp)
  # awk, not yq: the two yq implementations take different expressions and a
  # wrong guess would corrupt the only copy of the manifest on this node.
  # The mount is inserted at the head of the container's volumeMounts list, with
  # the same indentation the file already uses.
  awk '
    { print }
    !seeded && /^[[:space:]]*volumeMounts:[[:space:]]*$/ {
      ind = $0
      sub(/[^ ].*$/, "", ind)
      print ind "- mountPath: /var/log/audit-typo"
      print ind "  name: audit-typo"
      print ind "  readOnly: true"
      seeded = 1
    }
  ' "$KAS_MANIFEST" > "$TMP"

  if ! grep -q 'name: audit-typo' "$TMP"; then
    rm -f "$TMP"
    echo "no volumeMounts block found in $KAS_MANIFEST; refusing to guess what to break"
    exit 1
  fi
  cat "$TMP" > "$KAS_MANIFEST"
  rm -f "$TMP"
fi

echo "a volumeMounts entry named audit-typo, mounted at /var/log/audit-typo, with no matching entry under spec.volumes" > "$CKS_STATE_DIR/q37.fault"

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
echo "  Manifest:   $KAS_MANIFEST"
if [[ "$down" -eq 1 ]]; then
  echo "  State:      the API server is down and kubectl no longer answers"
else
  echo "  State:      the API server still answers. The kubelet rescans the manifest"
  echo "              directory about every 20 seconds, so give it a moment."
fi
echo "  The container was never created, so it has no log. Read the kubelet journal."
echo "  Spoiler:    what was changed is written to $CKS_STATE_DIR/q37.fault."
echo "              Open it only if you are stuck."
