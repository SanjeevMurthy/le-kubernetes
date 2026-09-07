#!/bin/bash
# Q22 kubelet CIS hardening: Verify
source "$(dirname "$0")/../../lib/checks.sh"
source "$(dirname "$0")/../../lib/env.sh"

CONF=/var/lib/kubelet/config.yaml
W=$(worker_node)
TMP=$(mktemp)
on_worker cat "$CONF" > "$TMP" 2>/dev/null || true

echo "Reading $CONF from ${W:-the worker}..."
check "the kubelet config could be read from the worker" test -s "$TMP"

# Read the effective values rather than grepping for a pattern, so that
# authentication.webhook.enabled is never mistaken for the anonymous key.
VALS=$(awk '
  /^[A-Za-z]/       { top = $0; sub(/:.*/, "", top); sub2 = "" }
  /^  [A-Za-z]/     { sub2 = $0; sub(/^  /, "", sub2); sub(/:.*/, "", sub2) }
  top == "authentication" && sub2 == "anonymous" && /^    enabled:/ { v = $2; gsub(/[" \t\r]/, "", v); print "anonymous=" v; next }
  top == "authorization" && /^  mode:/ { v = $2; gsub(/[" \t\r]/, "", v); print "mode=" v; next }
  /^readOnlyPort:/  { v = $2; gsub(/[" \t\r]/, "", v); print "readOnlyPort=" v; next }
' "$TMP" 2>/dev/null)
val() { echo "$VALS" | grep -m1 "^$1=" | cut -d= -f2; }

echo "Checking CIS 4.2.1 - anonymous authentication..."
check_eq "authentication.anonymous.enabled is false" false "$(val anonymous)"

echo "Checking CIS 4.2.2 - authorization mode..."
check_eq "authorization.mode is Webhook" Webhook "$(val mode)"

echo "Checking CIS 4.2.4 - read-only port..."
check_eq "readOnlyPort is 0" 0 "$(val readOnlyPort)"

echo "Checking the node survived the change..."
check "the kubelet service is active on ${W:-the worker}" on_worker systemctl is-active --quiet kubelet
check_eq "node ${W:-<missing>} is Ready" True \
  "$(kjp node "$W" '' '{.status.conditions[?(@.type=="Ready")].status}')"

# Control first. A curl that fails because ssh or curl is broken would make the
# next check a false PASS, so prove the authenticated port still answers.
echo "Control test: the kubelet still serves its authenticated port..."
check "https://127.0.0.1:10250/healthz on the worker accepts the connection" \
  on_worker curl -sk --max-time 3 -o /dev/null https://127.0.0.1:10250/healthz

echo "Effect test: the read-only port is really closed..."
check_not "http://127.0.0.1:10255/pods no longer answers" \
  on_worker curl -s --max-time 3 -o /dev/null http://127.0.0.1:10255/pods

echo "Re-running kube-bench for 4.2.1, 4.2.2 and 4.2.4 (effect test)..."
BENCH=$(printf '%s\n' 'kube-bench run --targets node --check 4.2.1,4.2.2,4.2.4 2>/dev/null | grep -c "\[PASS\]"' \
  | on_worker bash -s 2>/dev/null | tr -d ' \r')
check_eq "kube-bench reports three PASS lines" 3 "${BENCH:-0}"

rm -f "$TMP"
summary
