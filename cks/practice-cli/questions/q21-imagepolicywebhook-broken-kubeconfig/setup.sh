#!/bin/bash
# Q21 ImagePolicyWebhook: lay down an admission config that is fail-open and a
# webhook kubeconfig that is complete except for its server line, with none of
# it wired into the API server yet.
set -e
source "$(dirname "$0")/../../lib/env.sh"
require_node_root
require_tool kubectl

DIR=/etc/kubernetes/admission-controllers
CA=/etc/kubernetes/pki/ca.crt

[[ -f "$KAS_MANIFEST" ]] || { echo "missing $KAS_MANIFEST. Run this on the control-plane node."; exit 1; }
[[ -f "$CA" ]] || { echo "missing $CA. Run this on the control-plane node."; exit 1; }

backup_file "$KAS_MANIFEST" q21
mkdir -p "$DIR"

# The webhook kubeconfig has to name a CA file the API server can actually read.
# Reusing the cluster CA keeps the file loadable, so the only thing wrong with
# it is the one missing line.
cp -p "$CA" "$DIR/webhook-ca.crt"

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

# Complete in every respect except clusters[0].cluster.server. Wiring this file
# into the API server as it stands takes the API server down, which is the
# single most reported way candidates lose this question.
cat > "$DIR/kubeconfig.yaml" <<'EOF'
apiVersion: v1
kind: Config
clusters:
- name: bouncer_webhook
  cluster:
    certificate-authority: /etc/kubernetes/admission-controllers/webhook-ca.crt
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

# The backend Service resolves but has no endpoints, so a fail-closed webhook
# rejects every pod. That is the state the question asks for.
kubectl apply -f - >/dev/null <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: image-bouncer
  namespace: default
spec:
  type: ClusterIP
  selector:
    app: image-bouncer
  ports:
  - name: https
    port: 1323
    targetPort: 1323
EOF

# Start from a control plane with no ImagePolicyWebhook wiring at all so that a
# rerun always presents the same problem.
changed=0
if grep -q -- '--admission-control-config-file=' "$KAS_MANIFEST"; then
  sed -i '/--admission-control-config-file=/d' "$KAS_MANIFEST"; changed=1
fi
if grep -q 'ImagePolicyWebhook' "$KAS_MANIFEST"; then
  sed -i 's/,ImagePolicyWebhook//g; s/ImagePolicyWebhook,//g; /--enable-admission-plugins=ImagePolicyWebhook$/d' "$KAS_MANIFEST"
  changed=1
fi
if [[ "$changed" -eq 1 ]]; then
  echo "Removed leftover ImagePolicyWebhook wiring from the API server; waiting for it to come back..."
  wait_apiserver
fi

echo "Setup complete on node $(hostname):"
echo "  $DIR/admission-config.yaml   names ImagePolicyWebhook but is fail-open (defaultAllow: true)"
echo "  $DIR/kubeconfig.yaml         has certificate-authority but NO server line"
echo "  $DIR/webhook-ca.crt          a readable CA, so only the server line is missing"
echo "  Service image-bouncer in namespace default   ClusterIP on port 1323, no endpoints"
echo "  $KAS_MANIFEST                has no --admission-control-config-file, no"
echo "                               ImagePolicyWebhook and no mount for $DIR"
echo "  The API server is up. Check the kubeconfig before you wire it in."
