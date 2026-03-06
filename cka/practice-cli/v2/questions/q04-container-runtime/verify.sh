#!/bin/bash
# Q4 — Install Container Runtime and Prepare Node: Verify
PASS=0; FAIL=0

echo "Checking kernel module: overlay..."
if lsmod | grep -q "^overlay"; then
  echo "  PASS: overlay module is loaded"
  ((PASS++))
else
  echo "  FAIL: overlay module is not loaded"
  ((FAIL++))
fi

echo "Checking kernel module: br_netfilter..."
if lsmod | grep -q "^br_netfilter"; then
  echo "  PASS: br_netfilter module is loaded"
  ((PASS++))
else
  echo "  FAIL: br_netfilter module is not loaded"
  ((FAIL++))
fi

echo "Checking sysctl net.bridge.bridge-nf-call-iptables = 1..."
VAL=$(sysctl -n net.bridge.bridge-nf-call-iptables 2>/dev/null || echo "0")
if [[ "$VAL" == "1" ]]; then
  echo "  PASS: net.bridge.bridge-nf-call-iptables = 1"
  ((PASS++))
else
  echo "  FAIL: net.bridge.bridge-nf-call-iptables = $VAL (expected 1)"
  ((FAIL++))
fi

echo "Checking sysctl net.ipv4.ip_forward = 1..."
VAL=$(sysctl -n net.ipv4.ip_forward 2>/dev/null || echo "0")
if [[ "$VAL" == "1" ]]; then
  echo "  PASS: net.ipv4.ip_forward = 1"
  ((PASS++))
else
  echo "  FAIL: net.ipv4.ip_forward = $VAL (expected 1)"
  ((FAIL++))
fi

echo "Checking containerd service is running..."
if systemctl is-active containerd &>/dev/null; then
  echo "  PASS: containerd is active"
  ((PASS++))
else
  echo "  FAIL: containerd is not active"
  ((FAIL++))
fi

echo "Checking containerd config has SystemdCgroup = true..."
CONTAINERD_CONFIG="/etc/containerd/config.toml"
if [[ -f "$CONTAINERD_CONFIG" ]] && grep -q "SystemdCgroup = true" "$CONTAINERD_CONFIG" 2>/dev/null; then
  echo "  PASS: SystemdCgroup = true found in containerd config"
  ((PASS++))
else
  echo "  FAIL: SystemdCgroup = true not found in $CONTAINERD_CONFIG"
  ((FAIL++))
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
