#!/bin/bash
# Q02 process and I/O: start one long-lived reader that really touches the disk.
# It drops the page cache for its own file after each pass with posix_fadvise,
# so /proc/PID/io read_bytes keeps growing and pidstat -d has something to show.
source "$(dirname "$0")/../../lib/env.sh"
require_root "$@"

DIR=$(course_dir 2)
FILE="$DIR/bigfile"
STATE="$LFCS_STATE_DIR/q02"
mkdir -p "$STATE"

command -v pidstat >/dev/null 2>&1 || pkg_install sysstat
if ! has_needs "tool:pidstat"; then
  echo "pidstat is still missing. Install the sysstat package and run setup again."
  exit 1
fi

pkill -f 'lfcs-reader' >/dev/null 2>&1
rm -f "$DIR/pid.txt"

cat > "$STATE/reader.py" <<'PYEOF'
import os
import sys

path = sys.argv[1]
size = 1 << 20
while True:
    fd = os.open(path, os.O_RDONLY)
    while os.read(fd, size):
        pass
    try:
        os.posix_fadvise(fd, 0, 0, os.POSIX_FADV_DONTNEED)
    except OSError:
        pass
    os.close(fd)
PYEOF

if [[ ! -f "$FILE" ]]; then
  dd if=/dev/urandom of="$FILE" bs=1M count=200 status=none
fi

setsid bash -c "exec -a lfcs-reader python3 '$STATE/reader.py' '$FILE'" </dev/null >/dev/null 2>&1 &
sleep 1

PID=$(pgrep -f 'lfcs-reader' | head -1)
if [[ -z "$PID" ]]; then
  echo "The reader process did not start. Check that python3 is installed."
  exit 1
fi
echo "$PID" > "$STATE/pid"
renice -n 0 -p "$PID" >/dev/null 2>&1

echo "Setup complete."
echo "  A 200 MB file is being read in a loop from $FILE"
echo "  The reader is running with nice 0. Find it yourself; the PID is not printed here."
echo "  Deliverable: $DIR/pid.txt containing only the PID"
echo "  Target nice value: 15"
