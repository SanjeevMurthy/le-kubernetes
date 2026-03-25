#!/bin/bash
set -e
# Q13 — Fix ServiceAccount Assignment: Setup
#
# Scenario: A Pod tries to list pods in the monitoring namespace via the K8s API.
# It uses "wrong-sa" which has NO permissions, so the API returns 403 Forbidden.
# The user must investigate the existing SAs/Roles/RoleBindings to find "monitor-sa"
# which has the correct get/list/watch permissions, then recreate the Pod with it.

# Clean prior state
kubectl delete namespace monitoring &>/dev/null || true
while kubectl get namespace monitoring &>/dev/null 2>&1; do sleep 1; done

# Create namespace
kubectl create namespace monitoring &>/dev/null

# --- Decoy ServiceAccount: admin-sa (has get,list on pods — missing "watch") ---
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

# --- Wrong ServiceAccount: wrong-sa (NO permissions at all) ---
kubectl create serviceaccount wrong-sa -n monitoring &>/dev/null

# --- Correct ServiceAccount: monitor-sa (get, list, watch on pods) ---
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

# --- Create Pod using wrong-sa — it tries to list pods and gets 403 ---
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
    image: busybox:1.36
    command:
    - sh
    - -c
    - |
      while true; do
        echo "\$(date): Attempting to list pods in monitoring namespace..."
        TOKEN=\$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
        wget -qO- --header="Authorization: Bearer \$TOKEN" \
          --no-check-certificate \
          https://kubernetes.default.svc/api/v1/namespaces/monitoring/pods 2>&1 || true
        echo ""
        sleep 10
      done
EOF

# Wait for pod to start and produce at least one error log
echo "Waiting for metrics-pod to start..."
kubectl wait --for=condition=Ready pod/metrics-pod -n monitoring --timeout=60s &>/dev/null || true
sleep 12
