#!/bin/bash
# Q38 SBOM: verify. The graded facts are that the document really parses as JSON,
# that it describes the right image, and that the count is a usable number.
source "$(dirname "$0")/../../lib/checks.sh"
source "$(dirname "$0")/../../lib/env.sh"

SBOM="$COURSE_DIR/38/sbom.json"
CNT="$COURSE_DIR/38/count.txt"

if ! command -v python3 >/dev/null 2>&1; then
  echo "  FAIL: python3 is needed to validate the SBOM. Install it and rerun."
  echo ""
  echo "Results: 0 passed, 1 failed"
  exit 1
fi

echo "Checking the SBOM at $SBOM..."
check "sbom.json exists and is not empty" test -s "$SBOM"
# tag-value SPDX is the bom default and reads fine to a human, so the only honest
# test of the format is handing the file to a JSON parser.
check "sbom.json parses as JSON" \
  python3 -c 'import json,sys; json.load(open(sys.argv[1]))' "$SBOM"
check_file_has "it is an SPDX document" 'spdxVersion' "$SBOM"
check_file_has "it describes the kube-proxy image" 'kube-proxy' "$SBOM"

echo "Checking the package count at $CNT..."
check "count.txt exists" test -f "$CNT"
COUNT=$(tr -d ' \t\r\n' < "$CNT" 2>/dev/null)
if [[ "$COUNT" =~ ^[0-9]+$ ]] && [[ "$COUNT" -gt 0 ]]; then
  echo "  PASS: count.txt holds a positive integer ($COUNT)"; PASS=$((PASS + 1))
else
  echo "  FAIL: count.txt should hold a positive integer and nothing else, got '${COUNT:-<empty>}'"; FAIL=$((FAIL + 1))
fi

summary
