#!/bin/bash
# Q35 text processing: generate a log with known per-address counts and a known
# number of 5xx lines, a URL list and a CSV, then record the expected answers so
# verify compares against a fixed result rather than recomputing the task.
source "$(dirname "$0")/../../lib/env.sh"
require_root "$@"

DIR=$(course_dir 35)
STATE="$LFCS_STATE_DIR/q35"
mkdir -p "$STATE"

LOG="$DIR/access.log"
URLS="$DIR/urls.txt"
CSV="$DIR/data.csv"

rm -f "$LOG" "$URLS" "$CSV" "$URLS.bak" \
      "$DIR/top-ips.txt" "$DIR/errors.txt" "$DIR/col3.txt"

add_lines() {   # add_lines ip count status
  local ip="$1" n="$2" code="$3" i
  for (( i = 0; i < n; i++ )); do
    printf '%s - - [07/Sep/2026:%02d:%02d:00 +0000] "GET /page%d HTTP/1.1" %s 2048\n' \
      "$ip" "$(( i % 24 ))" "$(( i % 60 ))" "$(( i % 9 ))" "$code" >> "$LOG"
  done
}

: > "$LOG"
add_lines 10.0.0.1 35 200
add_lines 10.0.0.1  5 500
add_lines 10.0.0.2 26 200
add_lines 10.0.0.2  4 503
add_lines 10.0.0.3 17 200
add_lines 10.0.0.3  3 502
add_lines 10.0.0.4 12 404
add_lines 10.0.0.5  7 301
add_lines 10.0.0.6  3 200
add_lines 10.0.0.7  2 500

# Shuffle so the addresses are interleaved. A grouped log would let a pipeline
# that forgets the sort before uniq pass by accident.
shuf "$LOG" -o "$LOG"

cat > "$URLS" <<'URLEOF'
http://intranet.lab.local/index.html
https://secure.lab.local/login
http://mirror.lab.local/pub/rocky/9
http://build.lab.local:8080/job/main
https://docs.lab.local/manual
http://packages.lab.local/ubuntu/dists
URLEOF

cat > "$CSV" <<'CSVEOF'
id,host,role,owner
1,node1,web,ana
2,node2,db,bob
3,node3,cache,carol
4,node4,web,dave
5,node5,db,erin
CSVEOF

awk '{print $1}' "$LOG" | sort | uniq -c | sort -rn | head -5 | awk '{print $1, $2}' > "$STATE/top-ips"
grep -E ' 5[0-9]{2} ' "$LOG" > "$STATE/errors"
awk -F, 'NR > 1 {print $3}' "$CSV" > "$STATE/col3"
grep -c 'http://' "$URLS" > "$STATE/http-count"
grep -c 'https://' "$URLS" > "$STATE/https-count"
wc -l < "$URLS" | tr -d ' ' > "$STATE/url-lines"

echo "Setup complete."
echo "  Inputs:  $LOG ($(wc -l < "$LOG" | tr -d ' ') lines), $URLS, $CSV"
echo "  access.log field layout: address, then the quoted request, then the status code"
echo "  Deliverables: top-ips.txt, errors.txt, col3.txt, plus urls.txt edited in place with urls.txt.bak beside it"
echo "  No previous output files are left in $DIR"
