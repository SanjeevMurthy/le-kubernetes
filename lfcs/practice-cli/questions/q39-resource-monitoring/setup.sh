#!/bin/bash
# Q39 monitoring: start one process that keeps a core busy, and clear any earlier
# answers. The PID is deliberately not printed; finding it is the task.
source "$(dirname "$0")/../../lib/env.sh"
require_root "$@"

DIR=$(course_dir 39)

pkill -f 'lfcs-burner' >/dev/null 2>&1
rm -f "$DIR/cpu.txt" "$DIR/cores.txt" "$DIR/load.txt" "$DIR/mem.txt" "$DIR/procs.txt"

setsid bash -c 'exec -a lfcs-burner sha256sum /dev/zero' </dev/null >/dev/null 2>&1 &
sleep 2

PID=$(pgrep -f 'lfcs-burner' | head -1)
if [[ -z "$PID" ]]; then
  echo "The CPU burner did not start. Setup failed."
  exit 1
fi

echo "Setup complete."
echo "  One process is now saturating a CPU. Find it yourself; its PID is not printed here."
echo "  Deliverables in $DIR: cpu.txt, cores.txt, load.txt, mem.txt, procs.txt"
echo "  Each file holds the bare value, with no label."
echo "  This host reports $(nproc) core(s) and a load of $(cut -d' ' -f1-3 /proc/loadavg)."
