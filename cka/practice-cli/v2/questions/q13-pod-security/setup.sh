#!/bin/bash
set -e
# Q13 — Enforce Pod Security Standards: Setup

kubectl create namespace secure-ns --dry-run=client -o yaml | kubectl apply -f - &>/dev/null
