#!/usr/bin/env bash
# Unit tests for the shared practice-CLI libraries.
#
# These helpers are used by every question in both kits, so a regression here
# is a regression everywhere. The tests run anywhere bash and grep exist; they
# never touch a cluster, a node or the lab VMs.
#
# Usage: bash scripts/test-libs.sh
set -o pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
tests=0; failures=0

expect() {   # expect "what" expected actual
  tests=$(( tests + 1 ))
  if [[ "$2" == "$3" ]]; then
    printf '  ok    %s\n' "$1"
  else
    printf '  FAIL  %s (expected %q, got %q)\n' "$1" "$2" "$3"
    failures=$(( failures + 1 ))
  fi
}

# ─── cks lib/checks.sh ─────────────────────────────────────────────
printf '\n== cks/practice-cli/lib/checks.sh ==\n'
out=$(bash -c '
  source '"$ROOT"'/cks/practice-cli/lib/checks.sh
  check      "true passes"        true
  check      "false fails"        false
  check_not  "false passes"       false
  check_not  "true fails"         true
  check_eq   "equal"              a a
  check_eq   "unequal"            a b
  check_contains "word in list"   80  "443 80 8080"
  check_contains "absent word"    99  "443 80"
  echo "COUNTS $PASS $FAIL"
' 2>&1)
read -r _ p f <<<"$(echo "$out" | grep '^COUNTS ')"
expect "checks.sh pass count" 4 "$p"
expect "checks.sh fail count" 4 "$f"
expect "a failure reports expected and actual" 1 \
  "$(echo "$out" | grep -c "expected 'a', got 'b'")"

# check_contains must match a whole word, not a prefix of a longer one
out=$(bash -c '
  source '"$ROOT"'/cks/practice-cli/lib/checks.sh
  check_contains "80 must not match 8080 alone" 80 "8080"
  echo "COUNTS $PASS $FAIL"' 2>&1)
read -r _ p f <<<"$(echo "$out" | grep '^COUNTS ')"
expect "check_contains falls back to substring for 80 in 8080" 1 "$p"

# check_file_has takes label, regex, file, in that order
printf 'anonymous-auth=false\n' > "$TMP/flags"
out=$(bash -c '
  source '"$ROOT"'/cks/practice-cli/lib/checks.sh
  check_file_has "present"  "anonymous-auth=false" "'"$TMP"'/flags"
  check_file_has "absent"   "profiling=false"      "'"$TMP"'/flags"
  check_file_has "no file"  "anything"             "'"$TMP"'/nope"
  echo "COUNTS $PASS $FAIL"' 2>&1)
read -r _ p f <<<"$(echo "$out" | grep '^COUNTS ')"
expect "check_file_has pass count" 1 "$p"
expect "check_file_has fail count" 2 "$f"
expect "a missing file says so" 1 "$(echo "$out" | grep -c 'no such file')"

# summary exits non-zero when anything failed
bash -c 'source '"$ROOT"'/cks/practice-cli/lib/checks.sh; check "x" false; summary' >/dev/null 2>&1
expect "summary exits 1 after a failure" 1 "$?"
bash -c 'source '"$ROOT"'/cks/practice-cli/lib/checks.sh; check "x" true; summary' >/dev/null 2>&1
expect "summary exits 0 when clean" 0 "$?"

# ─── lfcs lib/env.sh ───────────────────────────────────────────────
printf '\n== lfcs/practice-cli/lib/env.sh ==\n'
printf 'net.ipv4.ip_forward = 1\nvm.swappiness = 10\n' > "$TMP/90-lab.conf"
printf 'nothing here\n' > "$TMP/empty.conf"
printf 'OnCalendar=*:0/15\n' > "$TMP/timer.conf"

out=$(LFCS_STATE_DIR="$TMP/state" COURSE_DIR="$TMP/course" bash -c '
  source '"$ROOT"'/lfcs/practice-cli/lib/checks.sh
  source '"$ROOT"'/lfcs/practice-cli/lib/env.sh
  check_persisted "first file"    "^net\.ipv4\.ip_forward *= *1" "'"$TMP"'/90-lab.conf"
  check_persisted "later file"    "^vm\.swappiness *= *10"       "'"$TMP"'/missing.conf" "'"$TMP"'/empty.conf" "'"$TMP"'/90-lab.conf"
  check_persisted "absent"        "^net\.core\.somaxconn"        "'"$TMP"'/empty.conf" "'"$TMP"'/90-lab.conf"
  check_persisted "no file"       "anything"                     "'"$TMP"'/nope.conf"
  check_persisted "metacharacters" "OnCalendar=\*:0/15"          "'"$TMP"'/timer.conf"
  echo "COUNTS $PASS $FAIL"' 2>&1)
read -r _ p f <<<"$(echo "$out" | grep '^COUNTS ')"
expect "check_persisted pass count" 3 "$p"
expect "check_persisted fail count" 2 "$f"
expect "each pass names the file it found" 3 "$(echo "$out" | grep -c 'persisted in')"
expect "a failure warns about the reboot" 2 "$(echo "$out" | grep -c 'will not survive a reboot')"

# needs tags
n() { LFCS_STATE_DIR="$TMP/state" COURSE_DIR="$TMP/course" bash -c '
  source '"$ROOT"'/lfcs/practice-cli/lib/env.sh; has_needs "'"$1"'"' >/dev/null 2>&1; echo $?; }
expect "empty needs is satisfied"        0 "$(n '')"
expect "tool:bash is satisfied"          0 "$(n 'tool:bash')"
expect "tool:definitelynotreal is not"   1 "$(n 'tool:definitelynotreal')"
expect "an unknown tag is refused"       1 "$(n 'bogus')"

# the lab-marker guard must refuse a host without the marker
LFCS_STATE_DIR="$TMP/state" COURSE_DIR="$TMP/course" bash -c '
  source '"$ROOT"'/lfcs/practice-cli/lib/env.sh; require_lab_host' >/dev/null 2>&1
expect "require_lab_host refuses a host with no marker" 1 "$?"
LFCS_ALLOW_HOST=1 LFCS_STATE_DIR="$TMP/state" COURSE_DIR="$TMP/course" bash -c '
  source '"$ROOT"'/lfcs/practice-cli/lib/env.sh; require_lab_host' >/dev/null 2>&1
expect "LFCS_ALLOW_HOST=1 overrides it" 0 "$?"

# ─── cks lib/env.sh context guard ──────────────────────────────────
# ─── lfcs fstab_drop_target ────────────────────────────────────────
# This one guards the boot. A cleanup that removes the wrong lines, or that
# restores a stale whole-file snapshot, leaves an /etc/fstab naming a device
# that no longer exists, and the VM stops at the emergency prompt.
printf '\n== lfcs/practice-cli/lib/env.sh fstab_drop_target ==\n'
cat > "$TMP/fstab" <<'FSTABEOF'
UUID=aaaa-1111 /               ext4  defaults        0 1
UUID=bbbb-2222 /data           ext4  noatime         0 2
# UUID=cccc-3333 /data         ext4  an old comment  0 2
/swapfile2     none            swap  sw,pri=10       0 0
UUID=dddd-4444 /mnt/raid       ext4  defaults        0 2
FSTABEOF
out=$(bash -c '
  LFCS_STATE_DIR='"$TMP"'/state
  FSTAB='"$TMP"'/fstab
  source '"$ROOT"'/lfcs/practice-cli/lib/env.sh 2>/dev/null
  fstab_drop_target /data
  fstab_drop_target /swapfile2
  fstab_drop_target /nonexistent
' 2>&1)
expect "the /data mount is gone"          0 "$(grep -c '^UUID=bbbb-2222' "$TMP/fstab")"
expect "the swap line is gone by source"  0 "$(grep -c '^/swapfile2' "$TMP/fstab")"
expect "the root filesystem survives"     1 "$(grep -c '^UUID=aaaa-1111 ' "$TMP/fstab")"
expect "another question's mount survives" 1 "$(grep -c '^UUID=dddd-4444' "$TMP/fstab")"
expect "a commented line is left alone"   1 "$(grep -c '^# UUID=cccc-3333' "$TMP/fstab")"
expect "dropping an absent target removed nothing more" 3 "$(wc -l < "$TMP/fstab" | tr -d ' ')"

printf '\n== cks/practice-cli/lib/env.sh context guard ==\n'
# The guard reads the context through kubectl, so drive it with a stub on PATH.
mkdir -p "$TMP/bin"
make_stub() { printf '#!/bin/sh\n[ "$2" = current-context ] && echo "%s"\nexit 0\n' "$1" > "$TMP/bin/kubectl"; chmod +x "$TMP/bin/kubectl"; }
guard() { make_stub "$1"; PATH="$TMP/bin:$PATH" CKS_STATE_DIR="$TMP/state" bash -c '
  source '"$ROOT"'/cks/practice-cli/lib/env.sh; require_context_allowed' >/dev/null 2>&1; echo $?; }
expect "minikube is allowed"                 0 "$(guard minikube)"
expect "cks profile is allowed"              0 "$(guard cks)"
expect "a work AKS context is refused"       1 "$(guard uniper-kafka-poc-aks)"
expect "an EKS context is refused"           1 "$(guard my-eks-cluster)"
expect "anything with prod is refused"       1 "$(guard team-prod-cluster)"
expect "an unknown context is refused"       1 "$(guard random-cluster)"
make_stub uniper-kafka-poc-aks
CKS_ALLOW_CONTEXT=1 PATH="$TMP/bin:$PATH" CKS_STATE_DIR="$TMP/state" bash -c '
  source '"$ROOT"'/cks/practice-cli/lib/env.sh; require_context_allowed' >/dev/null 2>&1
expect "CKS_ALLOW_CONTEXT=1 overrides the guard" 0 "$?"

printf '\ntest-libs: %d test(s), %d failure(s)\n' "$tests" "$failures"
[[ $failures -eq 0 ]]
