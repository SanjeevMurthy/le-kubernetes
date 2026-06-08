#!/bin/bash
kubectl delete pod audited custom --ignore-not-found &>/dev/null
echo "Cleanup complete"
