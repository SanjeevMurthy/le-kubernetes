#!/bin/bash
# Q1 — cri-dockerd: Verify
set -e
PASS=0; FAIL=0

echo "🔍 Checking cri-docker service..."
if systemctl is-active cri-docker.service &>/dev/null; then
  echo "  ✅ cri-docker service is active"
  ((PASS++))
else
  echo "  ❌ cri-docker service is not active"
  ((FAIL++))
fi

echo "🔍 Checking sysctl net.bridge.bridge-nf-call-iptables..."
VAL=$(sysctl -n net.bridge.bridge-nf-call-iptables 2>/dev/null || echo "0")
if [[ "$VAL" == "1" ]]; then echo "  ✅ bridge-nf-call-iptables=1"; ((PASS++)); else echo "  ❌ bridge-nf-call-iptables=$VAL"; ((FAIL++)); fi

echo "🔍 Checking sysctl net.ipv4.ip_forward..."
VAL=$(sysctl -n net.ipv4.ip_forward 2>/dev/null || echo "0")
if [[ "$VAL" == "1" ]]; then echo "  ✅ ip_forward=1"; ((PASS++)); else echo "  ❌ ip_forward=$VAL"; ((FAIL++)); fi

echo "🔍 Checking persistent config in /etc/sysctl.d/..."
if grep -r "net.bridge.bridge-nf-call-iptables" /etc/sysctl.d/ &>/dev/null; then
  echo "  ✅ Persistent sysctl config found"
  ((PASS++))
else
  echo "  ❌ No persistent sysctl config in /etc/sysctl.d/"
  ((FAIL++))
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
