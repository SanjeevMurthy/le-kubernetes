#!/bin/bash
# Q21 NFS: Verify
source "$(dirname "$0")/../../lib/checks.sh"
source "$(dirname "$0")/../../lib/env.sh"

STATE="$LFCS_STATE_DIR/q21"
NS=nfs-peer
HOSTIP=10.99.21.1
UNIT=$(cat "$STATE/unit" 2>/dev/null)
[[ -n "$UNIT" ]] || { UNIT=nfs-server; [[ "$(distro)" == ubuntu ]] && UNIT=nfs-kernel-server; }
FSTAB_OK=$(cat "$STATE/fstab-ok" 2>/dev/null)
SHOWMOUNT=$(cat "$STATE/showmount" 2>/dev/null)

echo "Control test: the server is up and the source directory is there..."
check_eq "$UNIT is running" "active" "$(systemctl is-active "$UNIT" 2>/dev/null)"
check "the marker file exists in /srv/share" test -f /srv/share/marker
check "the peer namespace $NS exists" ip netns pids "$NS"

echo "Checking the live export table..."
EXPS=$(exportfs -s 2>/dev/null)
[[ -n "$EXPS" ]] || EXPS=$(exportfs -v 2>/dev/null | tr '\n' ' ')
LINE=$(printf '%s\n' "$EXPS" | grep '/srv/share' | head -1)
check "exportfs reports an export for /srv/share" test -n "$LINE"
check_contains "the export is offered to 10.0.0.0/8" "10.0.0.0/8" "$LINE"
check_contains "the export is read-write" "rw" "$LINE"
check_contains "the export does not squash root" "no_root_squash" "$LINE"

echo "Effect test: the export as the peer sees it..."
if [[ "$SHOWMOUNT" == yes ]] || showmount -e "$HOSTIP" >/dev/null 2>&1; then
  check_contains "the peer sees /srv/share in the export list on $HOSTIP" "/srv/share" \
    "$(in_peer "$NS" showmount -e "$HOSTIP" 2>/dev/null)"
else
  echo "  NOTE: showmount does not answer on this host, so the export list cannot be read from the peer."
  check "the peer can open a TCP connection to the NFS port on $HOSTIP" \
    in_peer "$NS" timeout 4 bash -c "exec 3<>/dev/tcp/$HOSTIP/2049"
fi

echo "Checking the client mount..."
FSTYPE=$(findmnt -no FSTYPE /mnt/share 2>/dev/null)
case "$FSTYPE" in nfs|nfs4) OKFS=yes ;; *) OKFS="no, findmnt reports '${FSTYPE:-nothing mounted}'" ;; esac
check_eq "the filesystem at /mnt/share is NFS" "yes" "$OKFS"
check_contains "the mount source is the share on $HOSTIP" "/srv/share" \
  "$(findmnt -no SOURCE /mnt/share 2>/dev/null)"
check_contains "the marker file is readable through the mount" "nfs-marker-ok" \
  "$(cat /mnt/share/marker 2>/dev/null)"

echo "Checking both halves survive a reboot..."
check_persisted "the export is written in /etc/exports" \
  '^[[:space:]]*/srv/share[[:space:]]+10\.0\.0\.0/8\([^)]*rw' /etc/exports /etc/exports.d/*.exports
check_persisted "no_root_squash is written in /etc/exports" \
  '^[[:space:]]*/srv/share[[:space:]]+10\.0\.0\.0/8\([^)]*no_root_squash' \
  /etc/exports /etc/exports.d/*.exports
check_persisted "the mount is in /etc/fstab as nfs" \
  '^[^#]*[[:space:]]/mnt/share[[:space:]]+nfs' /etc/fstab
check_persisted "the fstab line carries _netdev, so a boot cannot hang on it" \
  '^[^#]*[[:space:]]/mnt/share[[:space:]]+nfs[0-9]*[[:space:]]+[^[:space:]]*_netdev' /etc/fstab
# Setup starts the unit but leaves it disabled, so this grades the candidate's
# own systemctl enable and not something setup did for them.
check_eq "$UNIT is enabled, so the export is served again after a reboot" \
  "enabled" "$(systemctl is-enabled "$UNIT" 2>/dev/null)"

if [[ "$FSTAB_OK" == yes ]]; then
  check "findmnt --verify reports no problem with /etc/fstab" findmnt --verify
else
  echo "  NOTE: /etc/fstab already had a warning before this question started, so it is not graded."
fi

summary
