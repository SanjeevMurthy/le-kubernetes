#!/bin/bash
# Q17 audit: partial policy file present, apiserver has no audit flags.
set -e
source "$(dirname "$0")/../../lib/env.sh"
require_node_root
backup_file "$KAS_MANIFEST" q17
mkdir -p /etc/kubernetes/audit /var/log/kubernetes/audit
cat > /etc/kubernetes/audit/policy.yaml <<'EOF'
apiVersion: audit.k8s.io/v1
kind: Policy
omitStages:
  - "RequestReceived"
rules: []
EOF
if grep -q -- '--audit-' "$KAS_MANIFEST"; then
  sed -i '/--audit-/d' "$KAS_MANIFEST"; wait_apiserver
fi
echo "Setup complete: /etc/kubernetes/audit/policy.yaml has an empty rules list; kube-apiserver has no --audit-* flags; log dir /var/log/kubernetes/audit exists."
