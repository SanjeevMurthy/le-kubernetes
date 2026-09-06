#!/bin/bash
# Q5 cleanup: remove everything setup created.
source "$(dirname "$0")/../../lib/env.sh"
kubectl delete namespace app --ignore-not-found >/dev/null 2>&1
echo "Cleanup complete"
