#!/bin/bash
kubectl delete clusterpolicy restrict-registries allowed-registry --ignore-not-found &>/dev/null
echo "Cleanup complete (revert apiserver changes manually if you used ImagePolicyWebhook)"
