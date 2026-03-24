#!/bin/bash
set -e
# Q13 — Fix ServiceAccount Assignment: Setup

# Clean prior state
kubectl delete namespace monitoring &>/dev/null || true
while kubectl get namespace monitoring &>/dev/null 2>&1; do sleep 1; done

# Create namespace
kubectl create namespace monitoring &>/dev/null

# Create ServiceAccount: admin-sa (has get,list on pods — close but not enough)
kubectl create serviceaccount admin-sa -n monitoring &>/dev/null
kubectl apply -f - &>/dev/null <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: admin-sa-role
  namespace: monitoring
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list"]
EOF
kubectl create rolebinding admin-sa-binding \
  --role=admin-sa-role \
  --serviceaccount=monitoring:admin-sa \
  -n monitoring &>/dev/null

# Create ServiceAccount: wrong-sa (no permissions)
kubectl create serviceaccount wrong-sa -n monitoring &>/dev/null

# Create ServiceAccount: monitor-sa (correct — get,list,watch on pods)
kubectl create serviceaccount monitor-sa -n monitoring &>/dev/null
kubectl apply -f - &>/dev/null <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: monitor-sa-role
  namespace: monitoring
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]
EOF
kubectl create rolebinding monitor-sa-binding \
  --role=monitor-sa-role \
  --serviceaccount=monitoring:monitor-sa \
  -n monitoring &>/dev/null

# Create Pod with WRONG serviceAccount (wrong-sa)
kubectl apply -f - &>/dev/null <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: metrics-pod
  namespace: monitoring
spec:
  serviceAccountName: wrong-sa
  containers:
  - name: monitor
    image: nginx
EOF
