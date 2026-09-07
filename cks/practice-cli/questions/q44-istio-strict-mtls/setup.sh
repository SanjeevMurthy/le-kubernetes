#!/bin/bash
# Q44 Istio mTLS: a service inside the mesh, a client inside the mesh and a
# client outside it, with the namespace left in Istio's permissive default.
set -e
source "$(dirname "$0")/../../lib/env.sh"
require_tool kubectl

NS=mesh-lab
OUT=mesh-out

kubectl get crd peerauthentications.security.istio.io >/dev/null 2>&1 || {
  echo "Istio is not installed on this cluster (no peerauthentications.security.istio.io CRD)."
  echo "Use a playground with Istio, or install it with: istioctl install --set profile=demo -y"
  exit 1
}

kubectl create namespace "$NS" >/dev/null 2>&1 || true
kubectl create namespace "$OUT" >/dev/null 2>&1 || true
kubectl label namespace "$NS" istio-injection=enabled --overwrite >/dev/null
kubectl label namespace "$OUT" istio-injection- >/dev/null 2>&1 || true

# A PeerAuthentication left behind by a previous solve would make the lab start
# already solved.
kubectl -n "$NS" delete peerauthentication --all >/dev/null 2>&1 || true

# Recreated rather than reused, because the sidecar is injected at pod creation
# and a pod from a run before the label was set would have none.
kubectl -n "$NS" delete deployment httpbin --ignore-not-found >/dev/null 2>&1 || true
kubectl -n "$NS" delete pod mesh-client --ignore-not-found >/dev/null 2>&1 || true
kubectl -n "$OUT" delete pod curl --ignore-not-found >/dev/null 2>&1 || true

kubectl apply -n "$NS" -f - >/dev/null <<'YAML'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: httpbin
spec:
  replicas: 1
  selector: {matchLabels: {app: httpbin}}
  template:
    metadata: {labels: {app: httpbin}}
    spec:
      containers:
      - name: httpbin
        image: kennethreitz/httpbin
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: httpbin
spec:
  selector: {app: httpbin}
  ports:
  - name: http
    port: 80
    targetPort: 80
---
apiVersion: v1
kind: Pod
metadata:
  name: mesh-client
  labels: {app: mesh-client}
spec:
  containers:
  - name: client
    image: curlimages/curl:8.9.1
    command: ["sleep", "3600"]
YAML

kubectl apply -n "$OUT" -f - >/dev/null <<'YAML'
apiVersion: v1
kind: Pod
metadata:
  name: curl
  labels: {app: curl}
spec:
  containers:
  - name: curl
    image: curlimages/curl:8.9.1
    command: ["sleep", "3600"]
YAML

kubectl -n "$NS" rollout status deploy/httpbin --timeout=120s >/dev/null 2>&1 || true
kubectl -n "$NS" wait --for=condition=Ready pod/mesh-client --timeout=120s >/dev/null 2>&1 || true
kubectl -n "$OUT" wait --for=condition=Ready pod/curl --timeout=120s >/dev/null 2>&1 || true

HPOD=$(kubectl get pod -n "$NS" -l app=httpbin -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
SIDECARS=$(kubectl get pod -n "$NS" "$HPOD" -o jsonpath='{.spec.containers[*].name}' 2>/dev/null)
case "$SIDECARS" in
  *istio-proxy*) INJECTED=yes ;;
  *)             INJECTED=no ;;
esac

CODE=$(kubectl exec -n "$OUT" curl -c curl -- curl -s -o /dev/null -w '%{http_code}' --max-time 5 http://httpbin."$NS"/get 2>/dev/null | tr -d '[:space:]')

echo "Setup complete."
echo "  Mesh namespace:    $NS (istio-injection=enabled), deployment and service httpbin on port 80"
echo "  In-mesh client:    pod/mesh-client in $NS, container 'client'"
echo "  Outside the mesh:  pod/curl in $OUT, container 'curl', no sidecar"
echo "  httpbin pod:       ${HPOD:-<none>} with containers: ${SIDECARS:-<none>}"
if [[ "$INJECTED" != yes ]]; then
  echo "  WARNING: no istio-proxy container was injected. Check that istiod is running,"
  echo "           then run this setup again, or the question cannot be solved."
fi
echo "  No PeerAuthentication exists in $NS, so the mesh is in its PERMISSIVE default."
echo "  Plain HTTP from $OUT right now returns: ${CODE:-<no answer>}"
