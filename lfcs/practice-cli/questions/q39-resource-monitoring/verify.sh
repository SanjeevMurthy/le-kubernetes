#!/bin/bash
# Q39 monitoring: Verify
source "$(dirname "$0")/../../lib/checks.sh"
source "$(dirname "$0")/../../lib/env.sh"

DIR="$COURSE_DIR/39"

within() {   # within actual expected tolerance
  local a="$1" e="$2" t="$3" d
  [[ "$a" =~ ^[0-9]+$ ]] || return 1
  [[ "$e" =~ ^[0-9]+$ ]] || return 1
  if (( a > e )); then d=$(( a - e )); else d=$(( e - a )); fi
  (( d <= t ))
}

REAL=$(pgrep -f 'lfcs-burner' | head -1)

echo "Checking the scenario is still live..."
check "the CPU burner is still running" test -n "$REAL"
if [[ -z "$REAL" ]]; then
  echo "  The burner is gone, so the CPU answer cannot be graded. Run setup again."
  summary
  exit $?
fi

echo "Checking the busiest process..."
check "cpu.txt exists" test -s "$DIR/cpu.txt"
check_eq "cpu.txt holds the PID of the busiest process" "$REAL" \
  "$(tr -dc '0-9' < "$DIR/cpu.txt" 2>/dev/null)"

echo "Checking the core count..."
check_eq "cores.txt matches nproc" "$(nproc)" \
  "$(tr -dc '0-9' < "$DIR/cores.txt" 2>/dev/null)"

echo "Checking the load averages..."
check "load.txt holds three load averages on one line" \
  grep -Eq '^[[:space:]]*[0-9]+[.,][0-9]+[[:space:]]+[0-9]+[.,][0-9]+[[:space:]]+[0-9]+[.,][0-9]+[[:space:]]*$' "$DIR/load.txt"

echo "Checking memory and the process count, each within a margin..."
MEM_EXP=$(free -m | awk '/^Mem:/ {print $7}')
MEM_GOT=$(tr -dc '0-9' < "$DIR/mem.txt" 2>/dev/null)
check "mem.txt is within 15 percent of the available memory free -m reports ($MEM_EXP MiB)" \
  within "$MEM_GOT" "$MEM_EXP" "$(( MEM_EXP * 15 / 100 ))"

PROC_EXP=$(ps -e --no-headers | wc -l | tr -d ' ')
PROC_GOT=$(tr -dc '0-9' < "$DIR/procs.txt" 2>/dev/null)
check "procs.txt is within 20 of the process count ($PROC_EXP)" \
  within "$PROC_GOT" "$PROC_EXP" 20

echo ""
echo "Note: these are readings, not settings. There is nothing to persist, and"
echo "nothing here survives the moment the burner is stopped."

summary
