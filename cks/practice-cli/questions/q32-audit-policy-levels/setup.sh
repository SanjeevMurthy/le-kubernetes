#!/bin/bash
# Q32 audit policy order: leave an empty policy file, no --audit-* flags on the
# API server, and a namespace worth auditing.
set -e
source "$(dirname "$0")/../../lib/env.sh"
require_node_root
require_tool kubectl
[[ -f "$KAS_MANIFEST" ]] || { echo "missing $KAS_MANIFEST; run this on the control-plane node"; exit 1; }

POLICY_DIR=/etc/kubernetes/audit
POLICY="$POLICY_DIR/policy.yaml"
LOG_DIR=/var/log/kubernetes/audit
NS=prod

backup_file "$KAS_MANIFEST" q32

mkdir -p "$POLICY_DIR" "$LOG_DIR"
cat > "$POLICY" <<'EOF'
apiVersion: audit.k8s.io/v1
kind: Policy
omitStages:
  - "RequestReceived"
rules: []
EOF
chmod 0644 "$POLICY"

# A log left over from an earlier attempt would still hold entries written under
# the old policy, and the effect test reads the whole file. Start it empty.
rm -f "$LOG_DIR"/audit.log*

# The API server must start from a state with no audit wiring at all.
if grep -q -- '--audit-' "$KAS_MANIFEST"; then
  sed -i '/--audit-/d' "$KAS_MANIFEST"
  echo "Removing the existing --audit-* flags and waiting for kube-apiserver..."
  wait_apiserver
fi

if ! kubectl get namespace "$NS" >/dev/null 2>&1; then
  kubectl create namespace "$NS" >/dev/null
  kubectl label namespace "$NS" cks-lab=q32 --overwrite >/dev/null
fi
kubectl -n "$NS" delete secret db-creds --ignore-not-found >/dev/null 2>&1
kubectl -n "$NS" create secret generic db-creds --from-literal=password=cks-audit-probe >/dev/null

MOUNTED=no
grep -q "mountPath: *$POLICY_DIR" "$KAS_MANIFEST" && MOUNTED=yes
grep -q "mountPath: *$POLICY" "$KAS_MANIFEST" && MOUNTED=yes

echo "Setup complete on node $(hostname):"
echo "  Policy file:    $POLICY  (rules: [] , nothing is audited yet)"
echo "  Log directory:  $LOG_DIR  (empty)"
echo "  API server:     $KAS_MANIFEST has no --audit-* flag"
echo "  Policy mounted into the static pod already: $MOUNTED"
echo "  Namespace:      $NS with secret db-creds"
echo "  Remember that an audit policy is first match wins, so the rule order is graded."
