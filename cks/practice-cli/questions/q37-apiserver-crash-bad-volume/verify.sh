#!/bin/bash
# Q37 apiserver bad volume: verify. The graded facts are that the orphan mount is
# gone, that the rest of the manifest survived, and that the cluster is back.
source "$(dirname "$0")/../../lib/checks.sh"
source "$(dirname "$0")/../../lib/env.sh"

echo "Checking the static pod manifest..."
# Precondition for the check below: a missing file would make a grep for the
# orphan mount fail too, and that would look like a pass.
check "the manifest is still in place" test -f "$KAS_MANIFEST"
check_not "no audit-typo mount is left in the manifest" grep -q 'audit-typo' "$KAS_MANIFEST"

echo "Checking nothing else was thrown away with it..."
check_file_has "the manifest still mounts /etc/kubernetes/pki" 'mountPath: /etc/kubernetes/pki' "$KAS_MANIFEST"
check_file_has "the container is still kube-apiserver" 'name: kube-apiserver' "$KAS_MANIFEST"
check_file_has "the authorization modes are still set" '--authorization-mode=' "$KAS_MANIFEST"

echo "Checking the API server came back..."
check "kube-apiserver reports readyz ok" \
  bash -c 'curl -sk --max-time 5 https://127.0.0.1:6443/readyz | grep -q ok'
check "kubectl get nodes works again" kubectl get nodes

POD=$(kubectl get pods -n kube-system -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' 2>/dev/null \
  | grep '^kube-apiserver-' | head -1)
check_pod_running "static pod ${POD:-<missing>} is Running" "$POD" kube-system

summary
