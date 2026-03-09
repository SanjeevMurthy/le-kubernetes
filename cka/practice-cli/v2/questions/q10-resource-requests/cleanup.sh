#!/bin/bash
# Q10 — Resource Requests/Limits for Pending Pods: Cleanup
kubectl delete deployment resource-app -n default --ignore-not-found &>/dev/null
