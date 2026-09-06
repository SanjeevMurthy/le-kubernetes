#!/bin/bash
# Q22 kubelet CIS hardening: put three CIS section 4.2 failures back into the
# worker's kubelet configuration and restart the kubelet so they are live.
set -e
source "$(dirname "$0")/../../lib/env.sh"
require_node_root
require_tool kubectl

CONF=/var/lib/kubelet/config.yaml

W=$(worker_node)
[[ -n "$W" ]] || { echo "no worker node found"; exit 1; }

# Backs up the local copy for the common case of running this on the worker.
# The remote script below keeps its own copy, which is the one cleanup trusts.
backup_file "$CONF" q22

if ! on_worker command -v kube-bench >/dev/null 2>&1; then
  echo "warning: kube-bench is not on $W. Install it there with: sudo bash tools/install-tools.sh kube-bench"
fi

EDIT=$(mktemp)
cat > "$EDIT" <<'REMOTE'
set -e
CONF=/var/lib/kubelet/config.yaml
[ -f "$CONF" ] || { echo "missing $CONF on $(hostname)"; exit 1; }
[ -f "$CONF.q22bak" ] || cp -p "$CONF" "$CONF.q22bak"

# Track the current top-level and second-level key so that the edit lands on
# authentication.anonymous.enabled and not on authentication.webhook.enabled.
# awk is used rather than yq because the two yq implementations in the wild take
# different expressions and a wrong guess corrupts the kubelet config.
rc=0
awk '
  /^[A-Za-z]/       { top = $0; sub(/:.*/, "", top); sub2 = "" }
  /^  [A-Za-z]/     { sub2 = $0; sub(/^  /, "", sub2); sub(/:.*/, "", sub2) }
  top == "authentication" && sub2 == "anonymous" && /^    enabled:/ { print "    enabled: true"; anon = 1; next }
  top == "authorization" && /^  mode:/ { print "  mode: AlwaysAllow"; mode = 1; next }
  /^readOnlyPort:/  { print "readOnlyPort: 10255"; rop = 1; next }
                    { print }
  END {
    if (!rop) print "readOnlyPort: 10255"
    if (!anon) exit 3
    if (!mode) exit 4
  }
' "$CONF.q22bak" > "$CONF.q22new" || rc=$?
if [ "${rc:-0}" -ne 0 ]; then
  rm -f "$CONF.q22new"
  if [ "$rc" -eq 3 ]; then echo "no authentication.anonymous.enabled key in $CONF; this is not a kubeadm kubelet config"; fi
  if [ "$rc" -eq 4 ]; then echo "no authorization.mode key in $CONF; this is not a kubeadm kubelet config"; fi
  exit 1
fi

grep -q '^readOnlyPort: 10255$' "$CONF.q22new" || { echo "edit did not take"; rm -f "$CONF.q22new"; exit 1; }
cat "$CONF.q22new" > "$CONF"
rm -f "$CONF.q22new"

systemctl restart kubelet
ok=0
i=0
while [ "$i" -lt 15 ]; do
  if systemctl is-active --quiet kubelet; then ok=1; break; fi
  i=$((i + 1))
  sleep 2
done
if [ "$ok" != 1 ]; then
  echo "the kubelet did not come back; restoring the original config"
  cp -p "$CONF.q22bak" "$CONF"
  systemctl restart kubelet
  exit 1
fi
echo "seeded on $(hostname)"
REMOTE

if ! on_worker bash -s < "$EDIT"; then
  rm -f "$EDIT"
  echo "Setup failed on $W. The kubelet configuration was left as it was."
  exit 1
fi
rm -f "$EDIT"

echo "Setup complete."
echo "  Worker node:        $W"
echo "  Kubelet config:     $CONF"
echo "  authentication.anonymous.enabled: true       (CIS 4.2.1 fails)"
echo "  authorization.mode: AlwaysAllow              (CIS 4.2.2 fails)"
echo "  readOnlyPort: 10255                          (CIS 4.2.4 fails)"
echo "  The kubelet has been restarted, so http://127.0.0.1:10255/pods answers on $W."
echo "  Audit it with: kube-bench run --targets node --check 4.2.1,4.2.2,4.2.4"
