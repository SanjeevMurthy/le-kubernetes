#!/bin/bash
# Q19 Falco output format: Verify
source "$(dirname "$0")/../../lib/checks.sh"
source "$(dirname "$0")/../../lib/env.sh"

LOCAL=/etc/falco/falco_rules.local.yaml
OUT="$COURSE_DIR/19/falco.log"

echo "Checking the shipped rules file was not edited..."
check_not "falco_rules.yaml still has no local override of the rule" \
  grep -q 'output:.*%evt.time,%container.id,%container.name,%user.name' /etc/falco/falco_rules.yaml

echo "Checking the local rules file overrides the rule..."
check_file_has "local rules declare 'Read sensitive file untrusted'" \
  '^- *rule: *Read sensitive file untrusted' "$LOCAL"
check_file_has "the required output format is set" \
  '%evt\.time,%container\.id,%container\.name,%user\.name' "$LOCAL"
check_file_has "priority stays WARNING" '^ *priority: *WARNING' "$LOCAL"

echo "Checking Falco is still running..."
if systemctl is-active --quiet falco-modern-bpf 2>/dev/null || systemctl is-active --quiet falco 2>/dev/null; then
  echo "  PASS: the Falco service is active"; PASS=$((PASS + 1))
else
  echo "  FAIL: neither falco-modern-bpf nor falco is active"; FAIL=$((FAIL + 1))
fi

echo "Checking the collected alerts..."
check "deliverable $OUT exists" test -f "$OUT"
if [[ -f "$OUT" ]]; then
  lines=$(grep -c . "$OUT")
  if [[ "$lines" -ge 5 ]]; then
    echo "  PASS: $lines alert lines collected (5 or more required)"; PASS=$((PASS + 1))
  else
    echo "  FAIL: only $lines alert lines, need at least 5"; FAIL=$((FAIL + 1))
  fi
  # Each line must be exactly four comma-separated fields: time, 12-hex container id, name, user.
  bad=$(grep -vcE '^[0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]+,[0-9a-f]{6,},[^,]+,[^,]+$' "$OUT" 2>/dev/null || echo 0)
  if [[ "$bad" -eq 0 ]]; then
    echo "  PASS: every line matches time,container-id,container-name,user-name"; PASS=$((PASS + 1))
  else
    echo "  FAIL: $bad line(s) do not match the required four-field format"; FAIL=$((FAIL + 1))
  fi
fi

summary
