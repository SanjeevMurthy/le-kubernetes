#!/bin/bash
kubectl delete sc local-storage --ignore-not-found
echo "✅ Cleanup complete"
