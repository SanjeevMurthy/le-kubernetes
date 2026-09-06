#!/bin/bash
# Q12 gVisor: remove the lab namespace and the RuntimeClass.
source "$(dirname "$0")/../../lib/env.sh"
kubectl delete namespace gvisor-lab --ignore-not-found >/dev/null 2>&1
kubectl delete runtimeclass gvisor --ignore-not-found >/dev/null 2>&1
echo "Cleanup complete"
