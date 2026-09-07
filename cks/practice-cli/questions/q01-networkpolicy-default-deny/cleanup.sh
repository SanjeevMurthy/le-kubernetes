#!/bin/bash
# Q1 cleanup: remove everything setup created.
source "$(dirname "$0")/../../lib/env.sh"
kubectl delete namespace netpol-lab --ignore-not-found >/dev/null 2>&1
echo "Cleanup complete"
