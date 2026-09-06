#!/bin/bash
# Q21 ImagePolicyWebhook: Verify
source "$(dirname "$0")/../../lib/checks.sh"
source "$(dirname "$0")/../../lib/env.sh"

DIR=/etc/kubernetes/admission-controllers
WEBHOOK_KUBECONFIG="$DIR/kubeconfig.yaml"
CFG="$DIR/admission-config.yaml"

echo "Checking the webhook kubeconfig at $WEBHOOK_KUBECONFIG..."
check_file_has "the cluster entry now has the server line" \
  '^[[:space:]]*server:[[:space:]]*https://image-bouncer\.default\.svc:1323/image_policy[[:space:]]*$' "$WEBHOOK_KUBECONFIG"
check_file_has "the certificate authority is still referenced" \
  'certificate-authority:[[:space:]]*/etc/kubernetes/admission-controllers/webhook-ca.crt' "$WEBHOOK_KUBECONFIG"

echo "Checking the admission configuration at $CFG..."
check_file_has "the webhook fails closed (defaultAllow: false)" 'defaultAllow:[[:space:]]*false' "$CFG"
check_not "no defaultAllow: true is left in the file" \
  bash -c '! test -f "$1" || grep -Eq "defaultAllow:[[:space:]]*true" "$1"' _ "$CFG"
check_file_has "it still points at the webhook kubeconfig" \
  'kubeConfigFile:[[:space:]]*/etc/kubernetes/admission-controllers/kubeconfig.yaml' "$CFG"

echo "Checking the API server wiring in $KAS_MANIFEST..."
check_file_has "--admission-control-config-file points at the admission config" \
  '--admission-control-config-file=/etc/kubernetes/admission-controllers/admission-config.yaml' "$KAS_MANIFEST"
check_file_has "ImagePolicyWebhook is in --enable-admission-plugins" \
  '--enable-admission-plugins=.*ImagePolicyWebhook' "$KAS_MANIFEST"
check_file_has "the admission directory is mounted into the pod" \
  'mountPath:[[:space:]]*/etc/kubernetes/admission-controllers' "$KAS_MANIFEST"
check_file_has "a hostPath volume exposes the admission directory" \
  'path:[[:space:]]*/etc/kubernetes/admission-controllers' "$KAS_MANIFEST"

echo "Checking the API server survived the change..."
check "kube-apiserver reports readyz ok" \
  bash -c 'curl -sk --max-time 5 https://127.0.0.1:6443/readyz | grep -q ok'
check "the webhook backend Service image-bouncer still exists" \
  kubectl get svc image-bouncer -n default

# Control first. If the API server refused everything, a denied pod would prove
# nothing, so establish that an object the plugin does not inspect still passes.
echo "Control test: an object the plugin ignores is still admitted..."
check "creating a namespace with --dry-run=server still succeeds" \
  kubectl create namespace ipw-control --dry-run=server

echo "Effect test: pod creation goes through ImagePolicyWebhook..."
if OUT=$(kubectl run ipw-probe --image=nginx --dry-run=server 2>&1); then
  echo "  FAIL: the pod was admitted, so the webhook is not enforcing"; FAIL=$((FAIL + 1))
elif echo "$OUT" | grep -qiE 'denied|rejected|forbidden|webhook|image_policy|imagepolicy|image-bouncer'; then
  echo "  PASS: the API server refused the pod through ImagePolicyWebhook"; PASS=$((PASS + 1))
else
  echo "  FAIL: the pod was refused for another reason: $(echo "$OUT" | head -1)"; FAIL=$((FAIL + 1))
fi

summary
