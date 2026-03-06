#!/bin/bash
# Q7 — Create HPA: Cleanup
kubectl delete hpa web-app -n default --ignore-not-found &>/dev/null
kubectl delete svc web-app -n default --ignore-not-found &>/dev/null
kubectl delete deployment web-app -n default --ignore-not-found &>/dev/null
