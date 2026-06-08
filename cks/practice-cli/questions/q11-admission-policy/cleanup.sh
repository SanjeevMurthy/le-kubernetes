#!/bin/bash
kubectl delete clusterpolicy restrict-registries --ignore-not-found &>/dev/null
echo "Cleanup complete"
