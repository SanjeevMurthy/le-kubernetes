#!/bin/bash
# Q10 — Encrypt Secrets at rest: Setup (control-plane node)
kubectl create secret generic pre-existing --from-literal=k=v 2>/dev/null || true
echo "A secret 'pre-existing' was created (default ns)."
echo "Configure EncryptionConfiguration (aescbc) at /etc/kubernetes/enc/enc.yaml, wire it into the"
echo "apiserver (--encryption-provider-config), then re-encrypt: kubectl get secrets -A -o json | kubectl replace -f -"
