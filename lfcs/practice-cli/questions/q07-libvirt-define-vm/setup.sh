#!/bin/bash
# Q07 libvirt: create the qcow2 image the task imports, and remove any domain
# left behind by an earlier run.
source "$(dirname "$0")/../../lib/env.sh"
require_root "$@"

if ! has_needs "virt tool:qemu-img"; then
  echo "This question needs libvirtd running and qemu-img installed."
  echo "  systemctl enable --now libvirtd"
  exit 1
fi

IMG=/var/lib/libvirt/images/lab.qcow2

virsh destroy labvm >/dev/null 2>&1
virsh undefine labvm --nvram >/dev/null 2>&1 || virsh undefine labvm >/dev/null 2>&1
rm -f /root/labvm.xml

mkdir -p /var/lib/libvirt/images
if [[ ! -f "$IMG" ]]; then
  qemu-img create -f qcow2 "$IMG" 1G >/dev/null
fi
command -v restorecon >/dev/null 2>&1 && restorecon -R /var/lib/libvirt/images >/dev/null 2>&1

echo "Setup complete."
echo "  Disk image:  $IMG"
echo "  $(qemu-img info "$IMG" 2>/dev/null | grep -E 'file format|virtual size' | tr '\n' ' ')"
echo "  Domains now: $(virsh list --all --name 2>/dev/null | tr '\n' ' ')"
echo "  Required:    a persistent domain named labvm, 512 MiB, 1 vCPU, autostart on, virt type qemu"
