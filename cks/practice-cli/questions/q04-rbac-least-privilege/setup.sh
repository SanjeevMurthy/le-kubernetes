#!/bin/bash
set -e
# Q4 — RBAC least-privilege: Setup (starts OVER-permissioned)
kubectl create namespace build 2>/dev/null || true
kubectl create serviceaccount ci -n build 2>/dev/null || true
kubectl create clusterrolebinding ci-admin --clusterrole=cluster-admin --serviceaccount=build:ci 2>/dev/null || true
echo "Setup complete: SA build:ci currently has cluster-admin via 'ci-admin'."
echo "Restrict it to get/list/watch pods,pods/log in 'build' only."
