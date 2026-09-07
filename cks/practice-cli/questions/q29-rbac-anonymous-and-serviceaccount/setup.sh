#!/bin/bash
# Q29 RBAC: plant two over-broad bindings, one for system:anonymous and one
# giving a ServiceAccount cluster-admin.
set -e
source "$(dirname "$0")/../../lib/env.sh"
require_tool kubectl

NS=rbac-lab

kubectl create namespace "$NS" >/dev/null 2>&1 || true
kubectl -n "$NS" delete serviceaccount reporter --ignore-not-found >/dev/null 2>&1 || true
kubectl -n "$NS" create serviceaccount reporter >/dev/null

# Wipe anything a previous solve left behind so the starting state is the same
# every run.
kubectl -n "$NS" delete rolebinding reporter --ignore-not-found >/dev/null 2>&1 || true
kubectl -n "$NS" delete role reporter --ignore-not-found >/dev/null 2>&1 || true

kubectl delete clusterrolebinding anon-viewer --ignore-not-found >/dev/null 2>&1 || true
kubectl create clusterrolebinding anon-viewer \
  --clusterrole=view --user=system:anonymous >/dev/null

kubectl delete clusterrolebinding reporter-admin --ignore-not-found >/dev/null 2>&1 || true
kubectl create clusterrolebinding reporter-admin \
  --clusterrole=cluster-admin --serviceaccount="$NS":reporter >/dev/null

# A live workload, so "list pods" has something to return.
kubectl -n "$NS" delete deployment web --ignore-not-found >/dev/null 2>&1 || true
kubectl -n "$NS" create deployment web --image=nginx:1.27 >/dev/null
kubectl -n "$NS" expose deployment web --port=80 >/dev/null 2>&1 || true

SA="system:serviceaccount:$NS:reporter"

echo "Setup complete:"
echo "  Finding 1: clusterrolebinding/anon-viewer binds user system:anonymous to the 'view' ClusterRole"
echo "  Finding 2: clusterrolebinding/reporter-admin binds $SA to cluster-admin"
echo "  Namespace: $NS holds serviceaccount/reporter, deployment/web and service/web"
echo "  Check permissions with:"
echo "    kubectl auth can-i <verb> <resource> --as=$SA -n $NS"
echo "  Right now that says yes to everything, including 'delete pods' and 'get nodes'."
