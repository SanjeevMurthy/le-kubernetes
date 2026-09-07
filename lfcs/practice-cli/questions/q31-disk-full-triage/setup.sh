#!/bin/bash
# Q31 disk-full triage: fill a small filesystem three ways, one of which is a
# deleted file held open by a running process, so du and df disagree.
source "$(dirname "$0")/../../lib/env.sh"

# Machine-readable output only: never let a locale reformat a number.
export LC_ALL=C
require_root "$@"

STATE="$LFCS_STATE_DIR/q31"
MP=/srv/data
mkdir -p "$STATE"

other=$(grep -lxF "$MP" "$LFCS_STATE_DIR"/q*/mountpoint 2>/dev/null | grep -v '/q31/mountpoint')
if [[ -n "$other" ]]; then
  echo "$MP is already claimed by another question ($other)."
  echo "Clean that question up first, then run this setup again."
  exit 1
fi

command -v lsof >/dev/null 2>&1 || pkg_install lsof
command -v lsof >/dev/null 2>&1 || echo "Note: lsof is not installed. 'lsof +L1' is the intended tool here."

backup_file /etc/fstab q31
# Give the holder time to die: while it lives the filesystem cannot be
# unmounted, and everything below would then run against a stale mount.
pkill -f lfcs-logwriter >/dev/null 2>&1
sleep 1
umount "$MP" 2>/dev/null
if [[ -f /etc/fstab ]]; then
  awk -v t="$MP" '$1 ~ /^#/ || $2 != t' /etc/fstab > "$STATE/fstab.tmp" &&
    cat "$STATE/fstab.tmp" > /etc/fstab
  rm -f "$STATE/fstab.tmp"
fi
rm -rf "$COURSE_DIR/31"

DEV=$(make_loop_disk d31 300)
if [[ -z "$DEV" || ! -b "$DEV" ]]; then
  echo "Could not create a loop-backed disk. Check that losetup has free devices."
  exit 1
fi
wipefs -aq "$DEV" 2>/dev/null
mkfs.ext4 -q -F -m 0 -L triage "$DEV" >/dev/null 2>&1

mkdir -p "$MP"
UUID=$(blkid -s UUID -o value "$DEV")
echo "UUID=$UUID  $MP  ext4  defaults  0  2" >> /etc/fstab
mount "$MP" || { echo "Could not mount $MP."; exit 1; }

# 1. Scratch files: visible to du, and the candidate is told they can go.
mkdir -p "$MP/tmp"
for i in 1 2 3 4 5 6 7 8; do
  dd if=/dev/zero of="$MP/tmp/session-$i.dmp" bs=1M count=5 status=none
done

# 2. The archive, which must stay, and holds the largest remaining file.
mkdir -p "$MP/archive"
dd if=/dev/zero of="$MP/archive/backup.tar" bs=1M count=50 status=none
dd if=/dev/zero of="$MP/archive/notes.tar" bs=1M count=3 status=none
echo "$MP/archive/backup.tar" > "$STATE/biggest"

# 3. The invisible 140 MB: a process still holding a file it has unlinked.
cat > "$STATE/holder.sh" <<'HOLDEREOF'
#!/bin/bash
# Write a large file, unlink it, and keep the descriptor open, which is exactly
# what a daemon does when someone deletes its log without restarting it.
f="$1"
exec 9>"$f"
dd if=/dev/zero bs=1M count=140 status=none >&9
rm -f "$f"
exec -a lfcs-logwriter sleep 86400
HOLDEREOF
setsid bash "$STATE/holder.sh" "$MP/.app-cache.bin" </dev/null >/dev/null 2>&1 &

for _ in $(seq 1 30); do
  used=$(df --output=pcent "$MP" 2>/dev/null | tail -1 | tr -dc '0-9')
  [[ "${used:-0}" -ge 75 ]] && break
  sleep 1
done
HPID=$(pgrep -f lfcs-logwriter | head -1)
if [[ -z "$HPID" ]]; then
  echo "The holder process did not start. Cannot set up this question."
  exit 1
fi
echo "$HPID" > "$STATE/holder.pid"

echo "$DEV" > "$STATE/devices"
echo "$MP" > "$STATE/mountpoint"
DIR=$(course_dir 31)

echo "Setup complete."
echo "  $MP is ext4 on $DEV, in /etc/fstab by UUID."
df -h "$MP" | sed 's/^/    /'
echo "  $MP/tmp is scratch. $MP/archive must not be touched."
echo "  Wanted: $MP under 60% used, and the path of the largest remaining file in $DIR/biggest.txt"
