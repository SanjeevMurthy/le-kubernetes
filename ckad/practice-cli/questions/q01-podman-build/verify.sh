#!/bin/bash
# Q1 — Build Container Image: Verify
PASS=0; FAIL=0

# Detect container runtime
if command -v podman &>/dev/null; then
  RUNTIME="podman"
elif command -v docker &>/dev/null; then
  RUNTIME="docker"
else
  echo "  FAIL: No container runtime found"
  exit 1
fi

echo "Checking image my-app:1.0 exists..."
if $RUNTIME images --format '{{.Repository}}:{{.Tag}}' 2>/dev/null | grep -q '^my-app:1.0$'; then
  echo "  PASS: Image my-app:1.0 exists"
  ((PASS++))
else
  ACTUAL=$($RUNTIME images --format '{{.Repository}}:{{.Tag}}' 2>/dev/null | head -5)
  echo "  FAIL: Image my-app:1.0 not found (available images: $ACTUAL)"
  ((FAIL++))
fi

echo "Checking /root/my-app.tar exists..."
if [[ -f /root/my-app.tar ]]; then
  echo "  PASS: /root/my-app.tar exists"
  ((PASS++))
else
  echo "  FAIL: /root/my-app.tar not found"
  ((FAIL++))
fi

echo "Checking /root/my-app.tar is non-empty..."
if [[ -s /root/my-app.tar ]]; then
  SIZE=$(du -h /root/my-app.tar | cut -f1)
  echo "  PASS: /root/my-app.tar is non-empty ($SIZE)"
  ((PASS++))
else
  echo "  FAIL: /root/my-app.tar is empty or missing"
  ((FAIL++))
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
