#!/bin/bash
kubectl delete secret pre-existing --ignore-not-found &>/dev/null
echo "Cleanup complete (revert apiserver/enc.yaml manually if desired)"
