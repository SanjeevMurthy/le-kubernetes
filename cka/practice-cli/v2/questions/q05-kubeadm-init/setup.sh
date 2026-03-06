#!/bin/bash
set -e
# Q5 — kubeadm Cluster Installation: Setup
# Verify kubeadm is available and create working directory

if ! command -v kubeadm &>/dev/null; then
  echo "ERROR: kubeadm is not installed on this node." >&2
  exit 1
fi

mkdir -p /root/kubeadm-task
