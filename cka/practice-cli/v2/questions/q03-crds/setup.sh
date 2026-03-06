#!/bin/bash
set -e
# Q3 — CRD Tasks - List, Query, Manage CRDs: Setup
# Install cert-manager CRDs and create namespace

kubectl create ns cert-manager --dry-run=client -o yaml | kubectl apply -f - &>/dev/null
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.0/cert-manager.crds.yaml &>/dev/null
rm -f /root/resources.yaml
