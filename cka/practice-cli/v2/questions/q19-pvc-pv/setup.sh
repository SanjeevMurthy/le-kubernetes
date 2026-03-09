#!/bin/bash
set -e
# Q19 — Create PVC and Bind to Existing PV: Setup

# Create StorageClass fast-storage if not exists
kubectl get storageclass fast-storage &>/dev/null 2>&1 || \
kubectl apply -f - &>/dev/null <<EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-storage
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
EOF

# Create PersistentVolume data-pv
kubectl apply -f - &>/dev/null <<EOF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: data-pv
spec:
  capacity:
    storage: 5Gi
  accessModes:
    - ReadWriteOnce
  storageClassName: fast-storage
  hostPath:
    path: /mnt/data
EOF
