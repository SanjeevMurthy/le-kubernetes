#!/bin/bash
# Q6 — Restrict the API server: Setup (node-level task)
echo "This task runs on the CONTROL-PLANE node."
echo "Back up then edit /etc/kubernetes/manifests/kube-apiserver.yaml to ensure:"
echo "  --anonymous-auth=false ; --authorization-mode=Node,RBAC ; --enable-admission-plugins=...,NodeRestriction"
