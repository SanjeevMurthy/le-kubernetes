#!/bin/bash
# Q5 ServiceAccount token hardening: verify.
source "$(dirname "$0")/../../lib/checks.sh"
source "$(dirname "$0")/../../lib/env.sh"

NS=app
TOKEN_DIR=/var/run/secrets/kubernetes.io/serviceaccount

echo "Checking the ServiceAccount and the pod spec..."
check_eq "ServiceAccount app-sa has automountServiceAccountToken: false" "false" "$(kjp sa app-sa "$NS" '{.automountServiceAccountToken}')"
check_eq "pod legacy runs as app-sa" "app-sa" "$(kjp pod legacy "$NS" '{.spec.serviceAccountName}')"

MOUNTS=$(kjp pod legacy "$NS" '{.spec.containers[*].volumeMounts[*].mountPath}')
check_not "no serviceaccount token is mounted into the container" grep -q "kubernetes.io/serviceaccount" <<<"$MOUNTS"

echo "Checking the pod is still running the workload..."
check_pod_running "pod legacy is Running" legacy "$NS"
# Precondition for the effect test: exec must work at all, otherwise the next
# check would pass for the wrong reason.
check "kubectl exec into legacy works" kubectl exec -n "$NS" legacy -- true

echo "Checking the token directory is really gone inside the container (effect test)..."
check_not "$TOKEN_DIR does not exist in the container" kubectl exec -n "$NS" legacy -- ls "$TOKEN_DIR"

summary
