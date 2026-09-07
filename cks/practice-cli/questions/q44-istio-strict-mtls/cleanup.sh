#!/bin/bash
# Q44 Istio mTLS: drop both namespaces. The PeerAuthentication is namespaced, so
# it goes with mesh-lab.
source "$(dirname "$0")/../../lib/env.sh"
kubectl delete namespace mesh-lab --ignore-not-found >/dev/null 2>&1
kubectl delete namespace mesh-out --ignore-not-found >/dev/null 2>&1
echo "Cleanup complete"
