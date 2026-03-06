#!/bin/bash
# Q11 — NGINX ConfigMap TLS Configuration: Cleanup
kubectl delete namespace nginx-tls --ignore-not-found &>/dev/null
