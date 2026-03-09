#!/bin/bash
set -e
# Q13 — Fix ServiceAccount Assignment: Setup

# Clean prior state
kubectl delete namespace monitoring &>/dev/null || true
while kubectl get namespace monitoring &>/dev/null 2>&1; do sleep 1; done

# Create namespace
kubectl create namespace monitoring &>/dev/null

# Create ServiceAccount: metrics-reader (has get,list on pods — close but not enough)
kubectl create serviceaccount metrics-reader -n monitoring &>/dev/null
kubectl apply -f - &>/dev/null <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: metrics-reader-role
  namespace: monitoring
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list"]
EOF
kubectl create rolebinding metrics-reader-binding \
  --role=metrics-reader-role \
  --serviceaccount=monitoring:metrics-reader \
  -n monitoring &>/dev/null

# Create ServiceAccount: log-reader (no permissions)
kubectl create serviceaccount log-reader -n monitoring &>/dev/null

# Create ServiceAccount: monitoring-sa (correct — get,list,watch on pods)
kubectl create serviceaccount monitoring-sa -n monitoring &>/dev/null
kubectl apply -f - &>/dev/null <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: monitoring-sa-role
  namespace: monitoring
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]
EOF
kubectl create rolebinding monitoring-sa-binding \
  --role=monitoring-sa-role \
  --serviceaccount=monitoring:monitoring-sa \
  -n monitoring &>/dev/null

# Create Pod with WRONG serviceAccount (log-reader)
kubectl apply -f - &>/dev/null <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: monitor-pod
  namespace: monitoring
spec:
  serviceAccountName: log-reader
  containers:
  - name: monitor
    image: nginx
EOF
