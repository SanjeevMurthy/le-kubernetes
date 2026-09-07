#!/bin/bash
# Q07 libvirt: Verify
source "$(dirname "$0")/../../lib/checks.sh"
source "$(dirname "$0")/../../lib/env.sh"

IMG=/var/lib/libvirt/images/lab.qcow2

echo "Checking the domain exists..."
check "virsh dominfo labvm reports a domain" virsh dominfo labvm
INFO=$(virsh dominfo labvm 2>/dev/null)
if [[ -z "$INFO" ]]; then
  echo "  No domain named labvm, so the remaining checks cannot mean anything."
  summary
  exit $?
fi

echo "Checking its shape..."
check_eq "Max memory is 524288 KiB, which is 512 MiB" "524288" \
  "$(echo "$INFO" | awk -F: '/Max memory/ {gsub(/[^0-9]/,"",$2); print $2}')"
check_eq "the domain has 1 vCPU" "1" \
  "$(echo "$INFO" | awk -F: '/^CPU\(s\)/ {gsub(/[^0-9]/,"",$2); print $2}')"
check_contains "the qcow2 image is attached" "$IMG" "$(virsh domblklist labvm 2>/dev/null)"

echo "Checking it starts by itself after a reboot..."
check_eq "virsh dominfo reports Autostart: enable" "enable" \
  "$(echo "$INFO" | awk -F: '/Autostart/ {gsub(/[[:space:]]/,"",$2); print $2}')"
check_persisted "the domain definition is on disk, not transient" \
  '<name>labvm</name>' /etc/libvirt/qemu/labvm.xml
check_persisted "the autostart symlink is on disk" \
  '<name>labvm</name>' /etc/libvirt/qemu/autostart/labvm.xml

summary
