#!/bin/bash
kubectl delete namespace appsec --ignore-not-found &>/dev/null
echo "Cleanup complete"
