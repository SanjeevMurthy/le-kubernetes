#!/bin/bash
# Q2 — CIS Benchmark / kube-bench: Setup (node-level task)
echo "This task runs on the CONTROL-PLANE node. Use kube-bench to find FAILs, then:"
echo "  - set --anonymous-auth=false in /etc/kubernetes/manifests/kube-apiserver.yaml"
echo "  - set readOnlyPort: 0 in /var/lib/kubelet/config.yaml (then restart kubelet)"
