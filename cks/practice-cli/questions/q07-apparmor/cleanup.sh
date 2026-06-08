#!/bin/bash
kubectl delete pod secure-pod --ignore-not-found &>/dev/null
echo "Cleanup complete"
