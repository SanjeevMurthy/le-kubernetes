#!/bin/bash
kubectl delete namespace payments --ignore-not-found &>/dev/null
echo "Cleanup complete"
