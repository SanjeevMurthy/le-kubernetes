#!/bin/bash
# Q14 ImagePolicyWebhook: admission config present but fail-open, apiserver not wired up.
set -e
source "$(dirname "$0")/../../lib/env.sh"
require_node_root
require_tool kubectl
DIR=/etc/kubernetes/admission-controllers
backup_file "$KAS_MANIFEST" q14
mkdir -p "$DIR"
cat > "$DIR/admission-config.yaml" <<'EOF'
apiVersion: apiserver.config.k8s.io/v1
kind: AdmissionConfiguration
plugins:
- name: ImagePolicyWebhook
  configuration:
    imagePolicy:
      kubeConfigFile: /etc/kubernetes/admission-controllers/kubeconfig.yaml
      allowTTL: 50
      denyTTL: 50
      retryBackoff: 500
      defaultAllow: true
EOF
cat > "$DIR/kubeconfig.yaml" <<'EOF'
apiVersion: v1
kind: Config
clusters:
- name: bouncer_webhook
  cluster:
    server: https://image-bouncer.default.svc:1323/image_policy
    insecure-skip-tls-verify: true
contexts:
- name: bouncer_validator
  context:
    cluster: bouncer_webhook
    user: api-server
current-context: bouncer_validator
preferences: {}
users:
- name: api-server
  user: {}
EOF
# Start from a control plane that has no ImagePolicyWebhook wiring at all.
changed=0
if grep -q -- '--admission-control-config-file=' "$KAS_MANIFEST"; then
  sed -i '/--admission-control-config-file=/d' "$KAS_MANIFEST"; changed=1
fi
if grep -q 'ImagePolicyWebhook' "$KAS_MANIFEST"; then
  sed -i 's/,ImagePolicyWebhook//g; s/ImagePolicyWebhook,//g; /--enable-admission-plugins=ImagePolicyWebhook$/d' "$KAS_MANIFEST"
  changed=1
fi
if [[ "$changed" -eq 1 ]]; then
  echo "Removed leftover ImagePolicyWebhook flags from the API server; waiting for it to come back..."
  wait_apiserver
fi
echo "Setup complete:"
echo "  - $DIR/admission-config.yaml exists but is fail-open (defaultAllow: true)"
echo "  - $DIR/kubeconfig.yaml points at https://image-bouncer.default.svc:1323/image_policy"
echo "  - kube-apiserver ($KAS_MANIFEST) has no --admission-control-config-file and no"
echo "    ImagePolicyWebhook in --enable-admission-plugins, and does not mount $DIR"
