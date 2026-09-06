#!/bin/bash
# Q27 Dockerfile and manifest hardening: verify.
source "$(dirname "$0")/../../lib/checks.sh"
source "$(dirname "$0")/../../lib/env.sh"

DIR="$COURSE_DIR/27"
DF="$DIR/Dockerfile"
MF="$DIR/deploy.yaml"
LINES="$CKS_STATE_DIR/q27.lines"

if [[ ! -f "$LINES" ]]; then
  echo "  FAIL: no original line counts recorded. Run setup first."
  echo ""; echo "Results: 0 passed, 1 failed"; exit 1
fi
D_ORIG=$(grep -m1 '^dockerfile=' "$LINES" | cut -d= -f2)
M_ORIG=$(grep -m1 '^manifest=' "$LINES" | cut -d= -f2)

# Precondition for every "must not contain" check below: without it, a deleted
# file would make each grep fail and every negative check would pass for the
# wrong reason.
echo "Checking both files are still there and still describe the same thing..."
check "$DF exists" test -s "$DF"
check "$MF exists" test -s "$MF"
check_file_has "the Dockerfile still starts from a base image" '^FROM ' "$DF"
check_file_has "the manifest is still the web Deployment" '^kind: *Deployment' "$MF"
check_file_has "the manifest still names the container web" 'name: *web' "$MF"

echo "Checking Dockerfile problem 1: the end-of-life base image..."
FROM_LINE=$(grep -m1 '^FROM ' "$DF" 2>/dev/null)
if [[ -z "$FROM_LINE" ]]; then
  echo "  FAIL: the Dockerfile has no FROM instruction any more"; FAIL=$((FAIL + 1))
elif echo "$FROM_LINE" | grep -q 'ubuntu:16.04'; then
  echo "  FAIL: the base image is still end of life ($FROM_LINE)"; FAIL=$((FAIL + 1))
else
  echo "  PASS: the base image was changed ($FROM_LINE)"; PASS=$((PASS + 1))
fi

echo "Checking Dockerfile problem 2: the final USER..."
USER_LINE=$(grep -E '^[[:space:]]*USER[[:space:]]' "$DF" 2>/dev/null | tail -1 | sed 's/[[:space:]]*$//')
USER_NAME=$(echo "$USER_LINE" | awk '{print $2}')
if [[ -z "$USER_LINE" ]]; then
  echo "  FAIL: the Dockerfile has no USER instruction, so the image still runs as root by default"; FAIL=$((FAIL + 1))
elif [[ "$USER_NAME" == "root" || "$USER_NAME" == "0" || "$USER_NAME" == 0:* ]]; then
  echo "  FAIL: the last USER instruction is still root ($USER_LINE)"; FAIL=$((FAIL + 1))
else
  echo "  PASS: the image ends as a non-root user ($USER_LINE)"; PASS=$((PASS + 1))
fi

echo "Checking manifest problem 1: privileged..."
if [[ ! -s "$MF" ]]; then
  echo "  FAIL: no manifest to check at $MF"; FAIL=$((FAIL + 1))
elif grep -Eq 'privileged:[[:space:]]*true' "$MF"; then
  echo "  FAIL: the container is still privileged"; FAIL=$((FAIL + 1))
else
  echo "  PASS: the container is no longer privileged"; PASS=$((PASS + 1))
fi

echo "Checking manifest problem 2: runAsUser..."
if [[ ! -s "$MF" ]]; then
  echo "  FAIL: no manifest to check at $MF"; FAIL=$((FAIL + 1))
elif grep -Eq 'runAsUser:[[:space:]]*"?0"?[[:space:]]*$' "$MF"; then
  echo "  FAIL: runAsUser is still 0"; FAIL=$((FAIL + 1))
else
  RU=$(grep -Em1 'runAsUser:' "$MF" | sed 's/.*runAsUser:[[:space:]]*//' | tr -d ' "\r')
  echo "  PASS: runAsUser is ${RU:-absent}, not 0"; PASS=$((PASS + 1))
fi

echo "Checking the edits were surgical (exam rule: change only what is asked)..."
drift() { # drift <label> <file> <original-count>
  local label="$1" f="$2" orig="$3" now d
  if [[ ! -f "$f" ]]; then
    echo "  FAIL: $label (no such file: $f)"; FAIL=$((FAIL + 1)); return
  fi
  now=$(wc -l < "$f" | tr -d ' ')
  d=$(( now - orig )); [[ $d -lt 0 ]] && d=$(( -d ))
  if [[ $d -le 2 ]]; then
    echo "  PASS: $label ($now lines, original $orig)"; PASS=$((PASS + 1))
  else
    echo "  FAIL: $label ($now lines, original $orig, drift $d is more than 2)"; FAIL=$((FAIL + 1))
  fi
}
drift "the Dockerfile was edited, not rewritten" "$DF" "$D_ORIG"
drift "the manifest was edited, not rewritten" "$MF" "$M_ORIG"

echo "Checking the settings that were already correct were left alone..."
check_file_has "allowPrivilegeEscalation is still false" 'allowPrivilegeEscalation:[[:space:]]*false' "$MF"
check_file_has "readOnlyRootFilesystem is still true" 'readOnlyRootFilesystem:[[:space:]]*true' "$MF"
check_file_has "the non-root user is still created in the image" 'useradd' "$DF"

summary
