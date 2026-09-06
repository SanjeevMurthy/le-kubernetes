#!/bin/bash
# Q18 immutable containers: verify.
source "$(dirname "$0")/../../lib/checks.sh"
source "$(dirname "$0")/../../lib/env.sh"

NS=immutable-lab

jp() { kjp deploy api "$NS" "$1"; }

RORF=$(jp '{.spec.template.spec.containers[0].securityContext.readOnlyRootFilesystem}')
APE=$(jp '{.spec.template.spec.containers[0].securityContext.allowPrivilegeEscalation}')
MNT=$(jp '{.spec.template.spec.containers[0].volumeMounts[*].mountPath}')

echo "Checking the hardened Deployment in $NS..."
check_eq "readOnlyRootFilesystem is true" "true" "$RORF"
check_eq "allowPrivilegeEscalation is false" "false" "$APE"
check_contains "a writable volume is mounted at /tmp" "/tmp" "$MNT"

echo "Checking the workload survived the hardening..."
check "rollout of deploy/api completed" kubectl rollout status deploy/api -n "$NS" --timeout=60s
pod=$(kubectl get pod -n "$NS" -l app=api -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
check_pod_running "pod ${pod:-<missing>} is Running with a read-only root" "$pod" "$NS"

echo "Checking the root filesystem is really read-only (effect test)..."
# Precondition: exec has to work and /tmp has to be writable, otherwise the
# denied write below would pass for the wrong reason.
check "the container can still write to /tmp" kubectl exec -n "$NS" deploy/api -- touch /tmp/probe
check_not "a write to /etc is denied inside the container" kubectl exec -n "$NS" deploy/api -- touch /etc/probe

summary
