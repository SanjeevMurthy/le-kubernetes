#!/bin/bash
# Q41 rogue service: verify. Read the sockets with ss -H so the check never
# depends on the shape of the human-readable header.
source "$(dirname "$0")/../../lib/checks.sh"
source "$(dirname "$0")/../../lib/env.sh"

UNIT=lab-fileshare.service
FILE=/etc/systemd/system/lab-fileshare.service
OUT="$COURSE_DIR/41/service.txt"
W=$(worker_node)

echo "Reading the listening TCP sockets on ${W:-the worker}..."
LISTEN=$(on_worker ss -H -ltn 2>/dev/null)
NL=$(echo "$LISTEN" | grep -c .)
# Precondition: a Kubernetes node always listens on something, the kubelet on
# 10250 at least. Zero lines means ss did not run over ssh, and "nothing is on
# 8888" would then be a PASS for the wrong reason.
if [[ "${NL:-0}" -lt 1 ]]; then
  echo "  FAIL: ss returned no listening sockets from ${W:-the worker}, so nothing below can be trusted"; FAIL=$((FAIL + 1))
  echo ""; echo "Results: $PASS passed, $FAIL failed"; exit 1
fi
echo "  PASS: read $NL listening sockets from ${W:-the worker}"; PASS=$((PASS + 1))

if echo "$LISTEN" | awk '{print $4}' | grep -Eq '(^|[:.])8888$'; then
  BOUND=$(echo "$LISTEN" | awk '{print $4}' | grep -E '(^|[:.])8888$' | tr '\n' ' ')
  echo "  FAIL: something still listens on TCP 8888: $BOUND"; FAIL=$((FAIL + 1))
else
  echo "  PASS: nothing listens on TCP 8888 any more"; PASS=$((PASS + 1))
fi

echo "Checking the unit is disabled and gone..."
STATE=$(on_worker systemctl is-enabled "$UNIT" 2>/dev/null | tr -d ' \r')
if [[ "$STATE" == "enabled" ]]; then
  echo "  FAIL: $UNIT is still enabled, so it would come back after a reboot"; FAIL=$((FAIL + 1))
else
  echo "  PASS: $UNIT is not enabled (systemctl is-enabled says '${STATE:-no such unit file}')"; PASS=$((PASS + 1))
fi

ACTIVE=$(on_worker systemctl is-active "$UNIT" 2>/dev/null | tr -d ' \r')
if [[ "$ACTIVE" == "active" ]]; then
  echo "  FAIL: $UNIT is still running"; FAIL=$((FAIL + 1))
else
  echo "  PASS: $UNIT is not running (systemctl is-active says '${ACTIVE:-unknown}')"; PASS=$((PASS + 1))
fi

# Precondition again: prove that a remote `test` reaches the worker at all,
# otherwise the absent-file check below passes whenever ssh is broken.
check "the unit directory /etc/systemd/system is readable on ${W:-the worker}" \
  on_worker test -d /etc/systemd/system
check_not "the unit file $FILE is gone" on_worker test -f "$FILE"

echo "Checking the node kept working..."
check "the kubelet is still active on ${W:-the worker}" on_worker systemctl is-active --quiet kubelet
check_eq "node ${W:-<missing>} is Ready" True \
  "$(kjp node "$W" '' '{.status.conditions[?(@.type=="Ready")].status}')"

echo "Checking the deliverable $OUT..."
check "$OUT exists and is not empty" test -s "$OUT"
# grep -c prints its count and exits 1 when the count is zero, so take the
# number it printed and never append a second one with `|| echo 0`.
LINES=$(grep -c . "$OUT" 2>/dev/null)
check_eq "$OUT holds exactly one non-empty line" 1 "${LINES:-0}"
ANS=$(grep -m1 . "$OUT" 2>/dev/null | tr -d ' \t\r')
if [[ "$ANS" =~ ^lab-fileshare(\.service)?$ ]]; then
  echo "  PASS: the service is named as '$ANS'"; PASS=$((PASS + 1))
else
  echo "  FAIL: expected the rogue unit name, got '${ANS:-<empty>}'"; FAIL=$((FAIL + 1))
fi

summary
