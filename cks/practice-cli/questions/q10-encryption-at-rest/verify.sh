#!/bin/bash
# Q10 — Verify (control-plane node)
PASS=0; FAIL=0
KAS=/etc/kubernetes/manifests/kube-apiserver.yaml
ENC=/etc/kubernetes/enc/enc.yaml
echo "Checking apiserver --encryption-provider-config flag..."
if [ -f "$KAS" ] && grep -q -- '--encryption-provider-config=' "$KAS"; then echo "  PASS"; ((PASS++)); elif [ ! -f "$KAS" ]; then echo "  FAIL: $KAS not found — run on control-plane node"; ((FAIL++)); else echo "  FAIL: encryption-provider-config flag not set"; ((FAIL++)); fi
echo "Checking EncryptionConfiguration uses an aescbc/aesgcm/secretbox provider..."
if [ -f "$ENC" ] && grep -Eq 'aescbc|aesgcm|secretbox' "$ENC"; then echo "  PASS"; ((PASS++)); elif [ ! -f "$ENC" ]; then echo "  FAIL: $ENC not found"; ((FAIL++)); else echo "  FAIL: no encryption provider in $ENC"; ((FAIL++)); fi
echo ""; echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
