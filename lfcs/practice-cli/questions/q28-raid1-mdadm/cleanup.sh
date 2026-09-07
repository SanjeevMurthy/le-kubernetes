#!/bin/bash
# Q28 RAID 1: Cleanup
source "$(dirname "$0")/../../lib/env.sh"
require_root "$@"

STATE="$LFCS_STATE_DIR/q28"
MDCONF=$(cat "$STATE/mdconf" 2>/dev/null)
[[ -z "$MDCONF" ]] && MDCONF=/etc/mdadm.conf
MDUUID=$(mdadm --detail --export /dev/md0 2>/dev/null | sed -n 's/^MD_UUID=//p')

umount /mnt/raid 2>/dev/null
mdadm --stop /dev/md0 >/dev/null 2>&1

fstab_drop_target /mnt/raid

restore_file "$MDCONF" q28
if [[ "$(cat "$STATE/mdconf-existed" 2>/dev/null)" == no && -f "$MDCONF" ]]; then
  pat='^ARRAY[[:space:]].*/dev/md/?0([[:space:]]|$)'
  [[ -n "$MDUUID" ]] && pat="$pat|^ARRAY[[:space:]].*UUID=$MDUUID"
  grep -vE "$pat" "$MDCONF" > /tmp/lfcs-q28-mdconf && cat /tmp/lfcs-q28-mdconf > "$MDCONF"
  rm -f /tmp/lfcs-q28-mdconf
fi

while read -r d; do
  [[ -b "$d" ]] || continue
  mdadm --zero-superblock "$d" >/dev/null 2>&1
  wipefs -aq "$d" 2>/dev/null
done < <(cat "$STATE/devices" 2>/dev/null)

free_loop_disk d28a
free_loop_disk d28b
findmnt -no TARGET /mnt/raid >/dev/null 2>&1 || rm -rf /mnt/raid
rm -rf "${LFCS_STATE_DIR:?}/q28"

echo "Cleanup complete. /mnt/raid unmounted, /dev/md0 stopped, superblocks zeroed, /etc/fstab and $MDCONF restored, loop disks d28a and d28b released."
echo "If you rebuilt the initramfs during the question, run 'update-initramfs -u' (Ubuntu) or 'dracut -f' (Rocky) once more so it forgets the array too."
