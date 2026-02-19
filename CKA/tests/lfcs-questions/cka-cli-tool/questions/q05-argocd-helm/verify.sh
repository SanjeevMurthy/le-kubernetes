#!/bin/bash
# Q5 — ArgoCD Helm: Verify
PASS=0; FAIL=0
echo "🔍 Checking namespace argocd..."
if kubectl get ns argocd &>/dev/null; then echo "  ✅ Namespace exists"; ((PASS++)); else echo "  ❌ Namespace not found"; ((FAIL++)); fi
echo "🔍 Checking /root/argo-helm.yaml..."
if [[ -f /root/argo-helm.yaml ]]; then echo "  ✅ File exists"; ((PASS++)); else echo "  ❌ Not found"; ((FAIL++)); fi
echo "🔍 Checking no CRDs in output..."
if ! grep -q "kind: CustomResourceDefinition" /root/argo-helm.yaml 2>/dev/null; then echo "  ✅ No CRDs"; ((PASS++)); else echo "  ❌ CRDs found in output"; ((FAIL++)); fi
echo ""; echo "Results: $PASS passed, $FAIL failed"; [[ $FAIL -eq 0 ]]
