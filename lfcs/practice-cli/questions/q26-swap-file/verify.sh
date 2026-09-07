#!/bin/bash
# Q26 swap file: Verify
source "$(dirname "$0")/../../lib/checks.sh"
source "$(dirname "$0")/../../lib/env.sh"

# Machine-readable output only: never let a locale reformat a number.
export LC_ALL=C

fstab_verify_clean() {
  local out
  out=$(findmnt --verify 2>&1)
  ! grep -qiE '[1-9][0-9]* (parse )?error' <<<"$out"
}

echo "Checking the file..."
check "/swapfile2 exists and is a regular file" test -f /swapfile2
check_eq "/swapfile2 is mode 600 owned by root" "600 root" \
  "$(stat -c '%a %U' /swapfile2 2>/dev/null)"

echo "Checking the live swap..."
check "/swapfile2 is in use as swap" \
  bash -c 'swapon --show=NAME --noheadings 2>/dev/null | grep -qx /swapfile2'
check_eq "the kernel sees it as a file, not a partition" "file" \
  "$(swapon --show=NAME,TYPE --noheadings 2>/dev/null | awk '$1=="/swapfile2" {print $2}')"
check_eq "its priority is 10" "10" \
  "$(swapon --show=NAME,PRIO --noheadings 2>/dev/null | awk '$1=="/swapfile2" {print $2}')"
check "it is about 512 MB" \
  awk -v k="$(awk '$1=="/swapfile2" {print $3}' /proc/swaps 2>/dev/null)" \
  'BEGIN {exit !(k + 0 >= 510000 && k + 0 <= 530000)}'

echo "Checking the swap survives a reboot..."
check_persisted "/etc/fstab activates /swapfile2 as swap at priority 10" \
  '^[[:space:]]*/swapfile2[[:space:]]+[^[:space:]]+[[:space:]]+swap[[:space:]]+[^[:space:]]*pri=10' \
  /etc/fstab
check "/etc/fstab parses cleanly (findmnt --verify)" fstab_verify_clean

summary
