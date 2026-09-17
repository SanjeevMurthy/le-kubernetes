#!/bin/bash
# Q48 Gatekeeper: remove only what the setup created. Gatekeeper itself was
# already on the cluster and is not this question's to uninstall, and a cluster
# may well carry other constraints that must survive.
source "$(dirname "$0")/../../lib/env.sh"
kubectl delete k8sallowedrepos allowed-registries --ignore-not-found >/dev/null 2>&1
kubectl delete constrainttemplate k8sallowedrepos --ignore-not-found >/dev/null 2>&1
kubectl delete namespace supply-lab supply-other --ignore-not-found >/dev/null 2>&1
echo "Cleanup complete"
