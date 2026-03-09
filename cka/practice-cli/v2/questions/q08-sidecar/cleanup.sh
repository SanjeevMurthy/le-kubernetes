#!/bin/bash
# Q8 — Add Sidecar Log Container: Cleanup
kubectl delete deployment app-deployment -n logging --ignore-not-found &>/dev/null
kubectl delete namespace logging --ignore-not-found &>/dev/null
