#!/bin/bash
# Q32 audit policy order: verify. A policy with the right rules in the wrong
# order silently audits nothing, so the line numbers are graded, not just the
# presence of each rule.
source "$(dirname "$0")/../../lib/checks.sh"
source "$(dirname "$0")/../../lib/env.sh"

P=/etc/kubernetes/audit/policy.yaml
L=/var/log/kubernetes/audit/audit.log
NS=prod

# check_order "label" first second   PASS when both lines exist and first < second
check_order() {
  if [[ -n "$2" && -n "$3" && "$2" -lt "$3" ]]; then
    echo "  PASS: $1 (lines $2 and $3)"; PASS=$((PASS + 1))
  else
    echo "  FAIL: $1 (found at lines '${2:-none}' and '${3:-none}')"; FAIL=$((FAIL + 1))
  fi
}
line_of() { grep -nE "$1" "$P" 2>/dev/null | sed -n "$2p" | cut -d: -f1; }

echo "Checking the four rules are present in $P..."
check_file_has "a RequestResponse rule exists" 'level: *RequestResponse' "$P"
check_file_has "the RequestResponse rule names secrets" 'secrets' "$P"
check_file_has "it is scoped to namespace prod" '(namespaces:.*prod|^[[:space:]]*-[[:space:]]*"?prod"?,?[[:space:]]*$)' "$P"
check_file_has "a None rule covers the non-resource URLs" 'nonResourceURLs' "$P"
check_file_has "the healthz endpoint is one of them" '/healthz' "$P"
check_file_has "a Metadata catch-all exists" 'level: *Metadata' "$P"

L_RR=$(line_of 'level: *RequestResponse' 1)
L_SEC=$(line_of 'secrets' 1)
L_NRU=$(line_of 'nonResourceURLs' 1)
L_NONE1=$(grep -nE 'level: *None' "$P" 2>/dev/null | head -1 | cut -d: -f1)
L_NONE2=$(grep -nE 'level: *None' "$P" 2>/dev/null | sed -n 2p | cut -d: -f1)
L_META=$(grep -nE 'level: *Metadata' "$P" 2>/dev/null | tail -1 | cut -d: -f1)
L_LAST=$(grep -nE '^[[:space:]]*-?[[:space:]]*level:' "$P" 2>/dev/null | tail -1 | cut -d: -f1)

echo "Checking the rule order, because the first match wins..."
check_order "the secrets rule is declared before the non-resource rule" "$L_RR" "$L_NRU"
check_order "the secrets resource belongs to that first rule" "$L_RR" "$L_SEC"
check_order "the secrets rule comes before the first None rule" "$L_RR" "$L_NONE1"
check_order "a second None rule follows the non-resource one" "$L_NRU" "$L_NONE2"
check_order "the None rules come before the Metadata catch-all" "$L_NONE2" "$L_META"
check_eq "the Metadata rule is the last rule in the file" "${L_LAST:-none}" "${L_META:-none}"

echo "Checking the second None rule drops get, list and watch..."
if [[ -n "$L_NONE2" && -n "$L_META" && "$L_NONE2" -lt "$L_META" ]]; then
  BLOCK=$(sed -n "${L_NONE2},${L_META}p" "$P" 2>/dev/null | tr -d '[]",')
  check_contains "verb get is dropped" "get" "$BLOCK"
  check_contains "verb list is dropped" "list" "$BLOCK"
  check_contains "verb watch is dropped" "watch" "$BLOCK"
else
  echo "  FAIL: could not read a None rule that sits above the Metadata rule"; FAIL=$((FAIL + 1))
fi

echo "Checking the five audit flags on the API server..."
check_file_has "--audit-policy-file points at $P" "--audit-policy-file=$P" "$KAS_MANIFEST"
check_file_has "--audit-log-path points at $L" "--audit-log-path=$L" "$KAS_MANIFEST"
check_file_has "--audit-log-maxage is 30" '--audit-log-maxage=30' "$KAS_MANIFEST"
check_file_has "--audit-log-maxbackup is 10" '--audit-log-maxbackup=10' "$KAS_MANIFEST"
check_file_has "--audit-log-maxsize is 100" '--audit-log-maxsize=100' "$KAS_MANIFEST"

# The hostPath type is read from the lines around the matching path, because a
# kubeadm manifest already carries several unrelated DirectoryOrCreate volumes.
vol_type() {
  awk -v p="$1" '
    { line[NR] = $0 }
    END {
      for (i = 1; i <= NR; i++) {
        if (line[i] ~ p) {
          for (j = i - 2; j <= i + 3; j++) {
            if (j >= 1 && j <= NR && line[j] ~ /^[[:space:]]*type:/) {
              t = line[j]
              sub(/^[[:space:]]*type:[[:space:]]*/, "", t)
              gsub(/["[:space:]]/, "", t)
              print t
              exit
            }
          }
        }
      }
    }' "$KAS_MANIFEST"
}

echo "Checking the two hostPath volumes and their types..."
check_file_has "the policy file is mounted into the pod" "mountPath: *$P" "$KAS_MANIFEST"
check_file_has "the log directory is mounted into the pod" 'mountPath: */var/log/kubernetes/audit' "$KAS_MANIFEST"
check_eq "the policy hostPath uses type File" "File" "$(vol_type 'path:[[:space:]]*/etc/kubernetes/audit/policy\.yaml')"
check_eq "the log hostPath uses type DirectoryOrCreate" "DirectoryOrCreate" "$(vol_type 'path:[[:space:]]*/var/log/kubernetes/audit/?[[:space:]]*$')"

echo "Checking the API server came back..."
check "the API server answers /readyz" bash -c 'curl -sk --max-time 5 https://127.0.0.1:6443/readyz | grep -q ok'
check "kubectl still reaches the cluster" kubectl get --raw /version

echo "Generating traffic and reading the log (effect test)..."
BEFORE=$(wc -l < "$L" 2>/dev/null); BEFORE=${BEFORE:-0}
kubectl -n "$NS" get secret db-creds >/dev/null 2>&1
kubectl -n "$NS" get pods >/dev/null 2>&1
kubectl -n "$NS" create configmap audit-probe --from-literal=k=v >/dev/null 2>&1
kubectl -n "$NS" delete configmap audit-probe >/dev/null 2>&1
sleep 3
AFTER=$(wc -l < "$L" 2>/dev/null); AFTER=${AFTER:-0}

check "the audit log file exists" test -s "$L"
if [[ "$AFTER" -gt "$BEFORE" ]]; then
  echo "  PASS: the audit log grew on API activity ($BEFORE -> $AFTER lines)"; PASS=$((PASS + 1))
else
  echo "  FAIL: the audit log did not grow ($BEFORE -> $AFTER lines)"; FAIL=$((FAIL + 1))
fi

SEC=$(grep '"level":"RequestResponse"' "$L" 2>/dev/null | grep -c '"resource":"secrets"')
if [[ "${SEC:-0}" -ge 1 ]]; then
  echo "  PASS: reading a Secret in $NS was recorded at RequestResponse ($SEC entries)"; PASS=$((PASS + 1))
else
  echo "  FAIL: no RequestResponse entry for secrets; the first rule is missing or sits below the None rule"; FAIL=$((FAIL + 1))
fi

PODLIST=$(grep '"resource":"pods"' "$L" 2>/dev/null | grep -c '"verb":"list"')
if [[ "${PODLIST:-0}" -eq 0 ]]; then
  echo "  PASS: no pod list was recorded, so the None rule is doing its job"; PASS=$((PASS + 1))
else
  echo "  FAIL: $PODLIST pod list entries were recorded; the None rule for get, list and watch is missing"; FAIL=$((FAIL + 1))
fi

summary
