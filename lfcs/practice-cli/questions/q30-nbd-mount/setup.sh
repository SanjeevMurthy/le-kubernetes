#!/bin/bash
# Q30 NBD: run a real nbd-server inside a network namespace, so the question
# needs no second VM. Nothing is created until both nbd-server and the nbd
# module are known to be present: a half-configured NBD lab is worse than none.
source "$(dirname "$0")/../../lib/env.sh"

# Machine-readable output only: never let a locale reformat a number.
export LC_ALL=C
require_root "$@"

STATE="$LFCS_STATE_DIR/q30"
NS=nbd-peer
IMG="$STATE/export.img"
CONF="$STATE/nbd-server.conf"

if ! command -v nbd-server >/dev/null 2>&1; then
  if [[ "$(distro)" == ubuntu ]]; then pkg_install nbd-server; else pkg_install nbd; fi
fi
if ! command -v nbd-server >/dev/null 2>&1; then
  echo "nbd-server is not installed and could not be installed automatically."
  echo "  Ubuntu: apt-get install -y nbd-server nbd-client"
  echo "  Rocky:  dnf install -y nbd        (needs EPEL)"
  echo "Nothing was created. Install it and run this setup again."
  exit 1
fi
if ! modinfo nbd >/dev/null 2>&1 && [[ ! -d /sys/module/nbd ]]; then
  echo "This kernel has no nbd module, so a network block device cannot be attached."
  echo "Nothing was created."
  exit 1
fi

mkdir -p "$STATE"
backup_file /etc/fstab q30

umount /mnt/nbd 2>/dev/null
nbd-client -d /dev/nbd0 >/dev/null 2>&1
if [[ -f /etc/fstab ]]; then
  awk '$1 ~ /^#/ || $2 != "/mnt/nbd"' /etc/fstab > "$STATE/fstab.tmp" &&
    cat "$STATE/fstab.tmp" > /etc/fstab
  rm -f "$STATE/fstab.tmp"
fi
rm -f /etc/modules-load.d/nbd.conf
rm -rf "$COURSE_DIR/30"

# The exported image, with the marker the candidate has to read back.
TOKEN=$(head -c 16 /dev/urandom | od -An -tx1 | tr -d ' \n')
rm -f "$IMG"
truncate -s 200M "$IMG"
mkfs.ext4 -q -F "$IMG" >/dev/null 2>&1
mkdir -p "$STATE/mnt"
mount -o loop "$IMG" "$STATE/mnt" || { echo "Could not stage the export image."; exit 1; }
echo "$TOKEN" > "$STATE/mnt/marker.txt"
umount "$STATE/mnt"
rmdir "$STATE/mnt"
echo "$TOKEN" > "$STATE/token"

PEER=$(make_netns_peer "$NS" 30)
cat > "$CONF" <<CONFEOF
[generic]
    user = root
    group = root
    listenaddr = 10.99.30.2
    port = 10809
[export]
    exportname = $IMG
    readonly = false
CONFEOF

in_peer "$NS" nbd-server -C "$CONF" >/dev/null 2>&1
sleep 1
if ! timeout 3 bash -c 'echo > /dev/tcp/10.99.30.2/10809' 2>/dev/null; then
  echo "nbd-server did not come up in the peer namespace. Cleaning up."
  del_netns_peer "$NS"
  exit 1
fi

DIR=$(course_dir 30)
echo /mnt/nbd > "$STATE/mountpoint"
mkdir -p /mnt/nbd

echo "Setup complete."
echo "  NBD server: $PEER port 10809, export name 'export' (200 MB, ext4, holds marker.txt)"
echo "  The nbd module is NOT loaded and /dev/nbd0 is not connected."
echo "  Wanted: /dev/nbd0 connected, mounted at /mnt/nbd, marker.txt copied to $DIR/token.txt,"
echo "  the module loading at boot, and an fstab line for /mnt/nbd with _netdev and noauto."
