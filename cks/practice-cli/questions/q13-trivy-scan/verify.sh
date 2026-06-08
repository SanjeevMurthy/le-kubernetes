#!/bin/bash
# Q13 — Verify
PASS=0; FAIL=0
IMG=$(kubectl get deploy web -n prod -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)
echo "Current image: $IMG"
echo "Checking the vulnerable nginx:1.18.0 was replaced with a patched nginx tag..."
if [[ "$IMG" == nginx:* && "$IMG" != "nginx:1.18.0" && "$IMG" != "nginx:latest" ]]; then
  echo "  PASS: image updated to $IMG"; ((PASS++))
else
  echo "  FAIL: image is '$IMG' — replace nginx:1.18.0 with a patched, pinned tag"; ((FAIL++))
fi
echo "Checking rollout is healthy..."
if kubectl rollout status deploy/web -n prod --timeout=30s &>/dev/null; then echo "  PASS: rollout complete"; ((PASS++)); else echo "  FAIL: deployment not fully rolled out"; ((FAIL++)); fi
echo ""; echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
