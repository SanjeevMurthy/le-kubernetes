#!/bin/bash
# Q35 Cilium L7: remove everything setup created.
source "$(dirname "$0")/../../lib/env.sh"
kubectl delete ciliumnetworkpolicy --all -n cilium-lab >/dev/null 2>&1
kubectl delete namespace cilium-lab --ignore-not-found >/dev/null 2>&1
echo "Cleanup complete"
