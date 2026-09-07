#!/bin/bash
# Q14 ImagePolicyWebhook: verify.
source "$(dirname "$0")/../../lib/checks.sh"; source "$(dirname "$0")/../../lib/env.sh"
CFG=/etc/kubernetes/admission-controllers/admission-config.yaml
echo "Checking the admission configuration at $CFG..."
check_file_has "the webhook fails closed (defaultAllow: false)" 'defaultAllow: *false' "$CFG"
check_file_has "it points at the webhook kubeconfig" 'kubeConfigFile: */etc/kubernetes/admission-controllers/kubeconfig.yaml' "$CFG"
echo "Checking the API server wiring in $KAS_MANIFEST..."
check_file_has "apiserver has --admission-control-config-file" '--admission-control-config-file=/etc/kubernetes/admission-controllers/admission-config.yaml' "$KAS_MANIFEST"
check_file_has "ImagePolicyWebhook is in --enable-admission-plugins" '--enable-admission-plugins=.*ImagePolicyWebhook' "$KAS_MANIFEST"
check_file_has "the admission directory is mounted into the pod" 'mountPath: */etc/kubernetes/admission-controllers' "$KAS_MANIFEST"
check_file_has "the admission directory has a hostPath volume" 'path: */etc/kubernetes/admission-controllers' "$KAS_MANIFEST"
check "apiserver is ready" bash -c 'curl -sk --max-time 5 https://127.0.0.1:6443/readyz | grep -q ok'
echo "Submitting a pod through admission (effect test)..."
if OUT=$(kubectl run ipw-probe --image=nginx --dry-run=server 2>&1); then
  echo "  FAIL: 'kubectl run ipw-probe --image=nginx --dry-run=server' was admitted; the webhook is not enforcing"; FAIL=$((FAIL + 1))
elif echo "$OUT" | grep -qiE 'denied|rejected|webhook|image_policy|imagepolicy|image-bouncer'; then
  echo "  PASS: the API server refused the pod through ImagePolicyWebhook"; PASS=$((PASS + 1))
else
  echo "  FAIL: the pod was refused for another reason: $(echo "$OUT" | head -1)"; FAIL=$((FAIL + 1))
fi
summary
