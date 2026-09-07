#!/bin/bash
# Q34 find and permissions: build a tree with a mix of owners and sizes, the
# auditor account, the devs group, and an ordinary directory to be turned into a
# collaboration directory. Record the expected result so verify can be exact.
source "$(dirname "$0")/../../lib/env.sh"
require_root "$@"

DIR=$(course_dir 34)
STATE="$LFCS_STATE_DIR/q34"
mkdir -p "$STATE"

# Record whether this question created the group and the account before creating
# either, so cleanup deletes only what it made. A host that already has a devs
# group or a real auditor user keeps them, home directory and all. The records
# are written once: a second setup run must not overwrite the first answer.
if [[ ! -f "$STATE/created-group" ]]; then
  if getent group devs >/dev/null 2>&1; then
    echo no > "$STATE/created-group"
  else
    echo yes > "$STATE/created-group"
  fi
fi
getent group devs >/dev/null 2>&1 || groupadd devs

if [[ ! -f "$STATE/created-user" ]]; then
  if id auditor >/dev/null 2>&1; then
    echo no > "$STATE/created-user"
  else
    echo yes > "$STATE/created-user"
  fi
fi
id auditor >/dev/null 2>&1 || useradd -m -s /bin/bash auditor
usermod -aG devs auditor

rm -rf "$DIR/data" "$DIR/found" "$DIR/shared"
rm -f "$DIR/suid.txt"
mkdir -p "$DIR/data/logs" "$DIR/data/nested/deep" "$DIR/shared"

dd if=/dev/zero of="$DIR/data/logs/alpha.bin"       bs=1M count=2   status=none
dd if=/dev/zero of="$DIR/data/logs/beta.bin"        bs=1M count=3   status=none
dd if=/dev/zero of="$DIR/data/nested/deep/gamma.bin" bs=1M count=2  status=none
dd if=/dev/zero of="$DIR/data/small.bin"            bs=1K count=200 status=none
dd if=/dev/zero of="$DIR/data/logs/root-big.bin"    bs=1M count=2   status=none

chown auditor:devs "$DIR/data/logs/alpha.bin" "$DIR/data/logs/beta.bin" \
                   "$DIR/data/nested/deep/gamma.bin" "$DIR/data/small.bin"
chmod 640 "$DIR/data/logs/alpha.bin"
chmod 600 "$DIR/data/logs/beta.bin"
chmod 644 "$DIR/data/nested/deep/gamma.bin"
chown root:root "$DIR/data/logs/root-big.bin"
chmod 644 "$DIR/data/logs/root-big.bin"

chgrp root "$DIR/shared"
chmod 755 "$DIR/shared"

: > "$STATE/modes"
for f in "$DIR/data/logs/alpha.bin" "$DIR/data/logs/beta.bin" "$DIR/data/nested/deep/gamma.bin"; do
  stat -c '%n %a %U' "$f" | sed "s|.*/||" >> "$STATE/modes"
done

echo "Setup complete."
echo "  Tree to search:  $DIR/data (five files, mixed owners and sizes)"
echo "  Account:         auditor, member of group devs"
echo "  Deliverables:    $DIR/found/ (copies), $DIR/suid.txt (one path per line)"
echo "  Directory to fix: $DIR/shared, now $(stat -c '%A %a %U:%G' "$DIR/shared")"
echo "  Target for shared: group devs, mode 3775"
