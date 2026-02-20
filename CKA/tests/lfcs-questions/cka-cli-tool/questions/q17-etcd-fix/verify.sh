#!/bin/bash
# Q17 — Etcd Fix: Verify
PASS=0; FAIL=0
echo "🔍 Checking kube-apiserver responds..."
if kubectl get nodes &>/dev/null; then echo "  ✅ API server responding"; ((PASS++)); else echo "  ❌ Not responding"; ((FAIL++)); fi
echo "🔍 Checking etcd endpoint uses port 2379..."
ETCD=$(grep "etcd-servers" /etc/kubernetes/manifests/kube-apiserver.yaml 2>/dev/null | grep 2379 || echo "")
if [[ -n "$ETCD" ]]; then echo "  ✅ Port 2379"; ((PASS++)); else echo "  ❌ Wrong port"; ((FAIL++)); fi
echo ""; echo "Results: $PASS passed, $FAIL failed"; [[ $FAIL -eq 0 ]]
