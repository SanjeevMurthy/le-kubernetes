#!/bin/bash
# Q31 disk-full triage: Verify
source "$(dirname "$0")/../../lib/checks.sh"
source "$(dirname "$0")/../../lib/env.sh"

# Machine-readable output only: never let a locale reformat a number.
export LC_ALL=C

STATE="$LFCS_STATE_DIR/q31"
MP=/srv/data
BIGGEST=$(cat "$STATE/biggest" 2>/dev/null)
if [[ -z "$BIGGEST" ]]; then
  echo "  FAIL: nothing recorded. Run setup first."
  echo ""; echo "Results: 0 passed, 1 failed"; exit 1
fi

fstab_verify_clean() {
  local out
  out=$(findmnt --verify 2>&1)
  ! grep -qiE '[1-9][0-9]* (parse )?error' <<<"$out"
}

deleted_holders() {   # exit 0 when any process holds a deleted file under $1
  local fd t
  for fd in /proc/[0-9]*/fd/*; do
    t=$(readlink "$fd" 2>/dev/null) || continue
    [[ "$t" == "$1/"*" (deleted)" ]] && return 0
  done
  return 1
}

probe_control() {   # prove the scan above can see one, before trusting a clean result
  local dir="$1" pid rc=1
  ( exec 9>"$dir/.lfcs-probe"; rm -f "$dir/.lfcs-probe"; exec -a lfcs-probe sleep 30 ) &
  pid=$!
  sleep 1
  deleted_holders "$dir" && rc=0
  kill "$pid" 2>/dev/null
  wait "$pid" 2>/dev/null
  return $rc
}

echo "Checking the filesystem is still there..."
check_eq "$MP is still mounted" "$MP" "$(findmnt -no TARGET "$MP" 2>/dev/null)"

echo "Checking the space was actually reclaimed..."
USED=$(df --output=pcent "$MP" 2>/dev/null | tail -1 | tr -dc '0-9')
if [[ -n "$USED" ]] && [[ "$USED" -lt 60 ]]; then
  echo "  PASS: $MP is under 60% used (now ${USED}%)"; PASS=$((PASS + 1))
else
  echo "  FAIL: $MP is ${USED:-unknown}% used, which is not under 60%"; FAIL=$((FAIL + 1))
fi

echo "Checking nothing is still holding deleted space..."
if probe_control "$MP"; then
  echo "  (control: the scan does find a deleted-but-open file when one exists)"
  check_not "no process is holding a deleted file on $MP" deleted_holders "$MP"
else
  echo "  FAIL: the deleted-file scan could not be validated, so its result means nothing"
  FAIL=$((FAIL + 1))
fi
check_eq "the process that was hiding the space is gone" "" \
  "$(pgrep -f lfcs-logwriter 2>/dev/null | tr '\n' ' ' | sed 's/ *$//')"

echo "Checking the archive was left alone..."
check "$BIGGEST still exists" test -f "$BIGGEST"

echo "Checking the deliverable..."
check_eq "$COURSE_DIR/31/biggest.txt names the largest remaining file" "$BIGGEST" \
  "$(tr -d ' \n\r' < "$COURSE_DIR/31/biggest.txt" 2>/dev/null)"

echo "Checking the mount still survives a reboot..."
DEV=$(head -1 "$STATE/devices" 2>/dev/null)
UUID=$(blkid -s UUID -o value "$DEV" 2>/dev/null)
if [[ -z "$UUID" ]]; then
  echo "  FAIL: $DEV has no filesystem UUID any more, so the fstab line cannot work"
  FAIL=$((FAIL + 1))
else
  check_persisted "/etc/fstab still mounts $MP by UUID=$UUID" \
    "^[^#]*UUID=\"?'?$UUID'?\"?[[:space:]]+$MP[[:space:]]" /etc/fstab
fi
check "/etc/fstab parses cleanly (findmnt --verify)" fstab_verify_clean

summary
