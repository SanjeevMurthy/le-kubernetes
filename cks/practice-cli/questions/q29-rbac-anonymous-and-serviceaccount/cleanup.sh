#!/bin/bash
# Q29 RBAC: remove the planted bindings and the lab namespace. The Role and
# RoleBinding the candidate created are namespaced, so they go with it.
source "$(dirname "$0")/../../lib/env.sh"
kubectl delete clusterrolebinding anon-viewer --ignore-not-found >/dev/null 2>&1
kubectl delete clusterrolebinding reporter-admin --ignore-not-found >/dev/null 2>&1
kubectl delete namespace rbac-lab --ignore-not-found >/dev/null 2>&1
echo "Cleanup complete"
