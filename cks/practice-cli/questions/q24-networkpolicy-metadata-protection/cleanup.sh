#!/bin/bash
# Q24 metadata endpoint: remove everything setup created.
source "$(dirname "$0")/../../lib/env.sh"
kubectl delete pod np-meta-check -n metadata-lab --ignore-not-found >/dev/null 2>&1
kubectl delete namespace metadata-lab --ignore-not-found >/dev/null 2>&1
echo "Cleanup complete"
