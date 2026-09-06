#!/bin/bash
# Q3 Ingress TLS: workload, service and an on-disk certificate; no secret, no ingress.
set -e
source "$(dirname "$0")/../../lib/env.sh"

NS=tls-lab
HOST=secure.example.com

require_tool openssl

kubectl create namespace "$NS" 2>/dev/null || true
kubectl -n "$NS" create deployment web --image=nginx 2>/dev/null || true
kubectl -n "$NS" expose deployment web --port=80 --target-port=80 2>/dev/null || true

# The candidate must build the secret and the ingress, so remove any leftovers.
kubectl -n "$NS" delete ingress web-ingress --ignore-not-found >/dev/null 2>&1 || true
kubectl -n "$NS" delete secret web-tls --ignore-not-found >/dev/null 2>&1 || true

D=$(course_dir 3)
if [[ ! -s "$D/web.crt" || ! -s "$D/web.key" ]]; then
  openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout "$D/web.key" -out "$D/web.crt" \
    -subj "/CN=$HOST/O=secure" -addext "subjectAltName=DNS:$HOST" >/dev/null 2>&1 ||
  openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout "$D/web.key" -out "$D/web.crt" \
    -subj "/CN=$HOST/O=secure" >/dev/null 2>&1
  chmod 600 "$D/web.key"
fi

kubectl -n "$NS" rollout status deploy/web --timeout=120s >/dev/null 2>&1 || echo "warning: deployment web is not ready yet"

echo "Setup complete: namespace '$NS' runs deployment 'web' behind service 'web' on port 80."
echo "A self-signed certificate and key for $HOST are on disk at $D/web.crt and $D/web.key."
echo "No secret 'web-tls' and no ingress 'web-ingress' exist yet, so nothing serves HTTPS."
echo "Ingress class in this cluster: $(kubectl get ingressclass -o jsonpath='{.items[*].metadata.name}' 2>/dev/null)."
