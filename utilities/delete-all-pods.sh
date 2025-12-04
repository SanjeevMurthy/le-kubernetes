#!/bin/bash

# Get the list of pods (optional, just to show what's there before deletion starts, 
# though delete --all will also list them as it deletes)
echo "Current pods:"
kubectl get pods

echo ""
echo "Deleting all pods in the current namespace..."

# Delete all pods at once
kubectl delete pods --all

echo "All pods deleted."
