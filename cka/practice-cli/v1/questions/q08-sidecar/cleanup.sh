#!/bin/bash
kubectl delete deployment wordpress --ignore-not-found
echo "✅ Cleanup complete"
