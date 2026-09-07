#!/bin/bash
# Q07 libvirt: Cleanup
source "$(dirname "$0")/../../lib/env.sh"
require_root "$@"

virsh destroy labvm >/dev/null 2>&1
virsh autostart --disable labvm >/dev/null 2>&1
virsh undefine labvm --nvram >/dev/null 2>&1 || virsh undefine labvm >/dev/null 2>&1
rm -f /var/lib/libvirt/images/lab.qcow2 /root/labvm.xml

echo "Cleanup complete. Domain labvm undefined, autostart symlink and lab.qcow2 removed."
