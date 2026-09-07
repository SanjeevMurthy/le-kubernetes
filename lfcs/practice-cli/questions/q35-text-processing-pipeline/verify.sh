#!/bin/bash
# Q35 text processing: Verify
source "$(dirname "$0")/../../lib/checks.sh"
source "$(dirname "$0")/../../lib/env.sh"

DIR="$COURSE_DIR/35"
STATE="$LFCS_STATE_DIR/q35"

echo "Checking the scenario is still in place..."
check "the inputs recorded by setup are present" test -s "$STATE/top-ips"
if [[ ! -s "$STATE/top-ips" ]]; then
  echo "  Setup did not record the expected answers, so nothing below can be graded. Run setup again."
  summary
  exit $?
fi

echo "Checking the top address report..."
check "top-ips.txt exists" test -s "$DIR/top-ips.txt"
check_eq "top-ips.txt has five lines" "5" "$(grep -c . "$DIR/top-ips.txt" 2>/dev/null)"
check_eq "top-ips.txt lists the five most frequent addresses with their counts, largest first" \
  "$(cat "$STATE/top-ips")" \
  "$(awk '{print $1, $2}' "$DIR/top-ips.txt" 2>/dev/null)"

echo "Checking the 5xx report..."
check "errors.txt exists" test -s "$DIR/errors.txt"
check_eq "errors.txt has one line per 5xx response" \
  "$(grep -c . "$STATE/errors")" "$(grep -c . "$DIR/errors.txt" 2>/dev/null)"
check "errors.txt matches the 5xx lines of the log exactly, in log order" \
  diff -q "$STATE/errors" "$DIR/errors.txt"

echo "Checking the URL rewrite..."
check "urls.txt still exists" test -s "$DIR/urls.txt"
check_eq "urls.txt has no plain http:// left" "0" "$(grep -c 'http://' "$DIR/urls.txt" 2>/dev/null)"
check_eq "urls.txt now carries every URL as https://" \
  "$(( $(cat "$STATE/http-count") + $(cat "$STATE/https-count") ))" \
  "$(grep -c 'https://' "$DIR/urls.txt" 2>/dev/null)"
check_eq "urls.txt still has the same number of lines" \
  "$(cat "$STATE/url-lines")" "$(wc -l < "$DIR/urls.txt" 2>/dev/null | tr -d ' ')"
check "the backup urls.txt.bak exists" test -s "$DIR/urls.txt.bak"
check_eq "the backup still holds the original http:// URLs" \
  "$(cat "$STATE/http-count")" "$(grep -c 'http://' "$DIR/urls.txt.bak" 2>/dev/null)"

echo "Checking the CSV column..."
check "col3.txt exists" test -s "$DIR/col3.txt"
check "col3.txt is the third field of every data line, in file order" \
  diff -q "$STATE/col3" "$DIR/col3.txt"

echo ""
echo "Note: this task has no configuration file to persist. The four output files"
echo "are the whole deliverable."

summary
