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
if [[ "$VAL" == "1" ]]; then echo "  ✅ bridge-nf-call-iptables=1"; ((PASS++)); else echo "  ❌ bridge-nf-call-iptables=$VAL (expected: 1)"; ((FAIL++)); fi

echo "🔍 Checking sysctl net.ipv6.conf.all.forwarding..."
VAL=$(sysctl -n net.ipv6.conf.all.forwarding 2>/dev/null || echo "0")
if [[ "$VAL" == "1" ]]; then echo "  ✅ ipv6.conf.all.forwarding=1"; ((PASS++)); else echo "  ❌ ipv6.conf.all.forwarding=$VAL (expected: 1)"; ((FAIL++)); fi

echo "🔍 Checking sysctl net.ipv4.ip_forward..."
VAL=$(sysctl -n net.ipv4.ip_forward 2>/dev/null || echo "0")
if [[ "$VAL" == "1" ]]; then echo "  ✅ ip_forward=1"; ((PASS++)); else echo "  ❌ ip_forward=$VAL (expected: 1)"; ((FAIL++)); fi

echo "🔍 Checking sysctl net.netfilter.nf_conntrack_max..."
VAL=$(sysctl -n net.netfilter.nf_conntrack_max 2>/dev/null || echo "0")
if [[ "$VAL" == "131072" ]]; then echo "  ✅ nf_conntrack_max=131072"; ((PASS++)); else echo "  ❌ nf_conntrack_max=$VAL (expected: 131072)"; ((FAIL++)); fi

echo "🔍 Checking persistent config in /etc/sysctl.d/..."
SYSCTL_OK=true
for PARAM in "net.bridge.bridge-nf-call-iptables" "net.ipv6.conf.all.forwarding" "net.ipv4.ip_forward" "net.netfilter.nf_conntrack_max"; do
  if ! grep -rq "$PARAM" /etc/sysctl.d/ 2>/dev/null; then
    SYSCTL_OK=false
    break
  fi
done
if $SYSCTL_OK; then
  echo "  ✅ All 4 parameters found in /etc/sysctl.d/"
  ((PASS++))
else
  echo "  ❌ Some parameters missing from /etc/sysctl.d/"
  ((FAIL++))
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
