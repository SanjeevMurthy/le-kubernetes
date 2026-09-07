#!/bin/bash
# Q40 CSR: an empty namespace with something to list and something to be
# refused, so the certificate issued for jane can be tested in both directions.
set -e
source "$(dirname "$0")/../../lib/env.sh"
require_tool kubectl
require_tool openssl

NS=csr-lab

kubectl create namespace "$NS" >/dev/null 2>&1 || true

# A previous solve leaves an approved CSR and a grant behind. Both have to go,
# or the verifier would pass before anything has been done this time.
kubectl delete csr jane --ignore-not-found >/dev/null 2>&1 || true
kubectl -n "$NS" delete rolebinding --all >/dev/null 2>&1 || true
kubectl -n "$NS" delete role --all >/dev/null 2>&1 || true

kubectl -n "$NS" delete deployment web --ignore-not-found >/dev/null 2>&1 || true
kubectl -n "$NS" create deployment web --image=nginx:1.27 --replicas=1 >/dev/null

kubectl -n "$NS" delete secret app-secret --ignore-not-found >/dev/null 2>&1 || true
kubectl -n "$NS" create secret generic app-secret --from-literal=token=lab-only-value >/dev/null

DIR=$(course_dir 40)
rm -f "$DIR/jane.key" "$DIR/jane.csr" "$DIR/jane.crt"

echo "Setup complete."
echo "  Namespace:     $NS holds deployment/web and secret/app-secret"
echo "  Work in:       $DIR   (jane.key, jane.csr, jane.crt go here)"
echo "  No CertificateSigningRequest named jane exists yet."
echo "  Right now every answer is no:"
echo "    kubectl auth can-i list pods -n $NS --as jane"
echo "  The cluster CA is /etc/kubernetes/pki/ca.crt on a kubeadm control plane,"
echo "  but the signer does the signing for you once the request is approved."
