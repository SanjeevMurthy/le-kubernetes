#!/bin/bash
# Q14 hostname and resolver: Verify
source "$(dirname "$0")/../../lib/checks.sh"
source "$(dirname "$0")/../../lib/env.sh"

WANT=node1.lab.local
[[ "$(distro)" == rocky ]] && WANT=node2.lab.local

echo "Checking the hostname..."
check_eq "hostnamectl --static reports $WANT" "$WANT" "$(hostnamectl --static 2>/dev/null)"
check_persisted "the hostname is written to disk" "^$WANT\$" /etc/hostname

echo "Checking name resolution for node9..."
check_contains "getent hosts node9 answers 192.168.56.90" "192.168.56.90" \
  "$(getent hosts node9 2>/dev/null)"
check_contains "getent hosts node9.lab.local answers 192.168.56.90" "192.168.56.90" \
  "$(getent hosts node9.lab.local 2>/dev/null)"
check_persisted "the entry for node9 is in the hosts file" \
  '^[[:space:]]*192\.168\.56\.90[[:space:]]+.*node9' /etc/hosts

echo "Checking the live resolver..."
LIVE=$( { resolvectl dns 2>/dev/null; resolvectl domain 2>/dev/null; cat /etc/resolv.conf 2>/dev/null; } )
check_contains "1.1.1.1 is a live nameserver" "1.1.1.1" "$LIVE"
check_contains "9.9.9.9 is a live nameserver" "9.9.9.9" "$LIVE"
check_contains "lab.local is a live search domain" "lab.local" "$LIVE"

echo "Checking the resolver survives a reboot..."
check_persisted "1.1.1.1 is written into the network configuration" \
  '1\.1\.1\.1' /etc/netplan/*.yaml /etc/netplan/*.yml \
  /etc/NetworkManager/system-connections/*.nmconnection \
  /etc/systemd/resolved.conf /etc/systemd/resolved.conf.d/*.conf \
  /etc/sysconfig/network-scripts/ifcfg-*
check_persisted "9.9.9.9 is written into the network configuration" \
  '9\.9\.9\.9' /etc/netplan/*.yaml /etc/netplan/*.yml \
  /etc/NetworkManager/system-connections/*.nmconnection \
  /etc/systemd/resolved.conf /etc/systemd/resolved.conf.d/*.conf \
  /etc/sysconfig/network-scripts/ifcfg-*
check_persisted "the lab.local search domain is written into the network configuration" \
  'lab\.local' /etc/netplan/*.yaml /etc/netplan/*.yml \
  /etc/NetworkManager/system-connections/*.nmconnection \
  /etc/systemd/resolved.conf /etc/systemd/resolved.conf.d/*.conf \
  /etc/sysconfig/network-scripts/ifcfg-*

summary
