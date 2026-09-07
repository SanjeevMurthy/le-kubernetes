#!/bin/bash
# Q11 cleanup: remove everything setup created.
source "$(dirname "$0")/../../lib/env.sh"
kubectl delete clusterpolicy restrict-registries --ignore-not-found >/dev/null 2>&1
kubectl delete namespace kyverno-lab --ignore-not-found >/dev/null 2>&1
echo "Cleanup complete"
