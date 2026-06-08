#!/bin/bash
kubectl delete namespace prod --ignore-not-found &>/dev/null
echo "Cleanup complete"
