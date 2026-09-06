#!/bin/bash
# Q17 audit logging: verify.
source "$(dirname "$0")/../../lib/checks.sh"; source "$(dirname "$0")/../../lib/env.sh"
P=/etc/kubernetes/audit/policy.yaml; L=/var/log/kubernetes/audit/audit.log
echo "Checking the audit policy at $P..."
check_file_has "policy logs secrets at RequestResponse" 'level: *RequestResponse' "$P"
check_file_has "policy mentions resource secrets" 'resources: *\[? *"?secrets' "$P"
check_file_has "policy has a Metadata catch-all" 'level: *Metadata' "$P"
echo "Checking the API server wiring in $KAS_MANIFEST..."
check_file_has "apiserver has --audit-policy-file" '--audit-policy-file=/etc/kubernetes/audit/policy.yaml' "$KAS_MANIFEST"
check_file_has "apiserver has --audit-log-path" "--audit-log-path=$L" "$KAS_MANIFEST"
check_file_has "policy file is mounted" 'mountPath: */etc/kubernetes/audit' "$KAS_MANIFEST"
check_file_has "log dir is mounted" 'mountPath: */var/log/kubernetes/audit' "$KAS_MANIFEST"
check "apiserver is ready" curl -sk --max-time 3 https://127.0.0.1:6443/readyz
echo "Reading secrets and watching $L (effect test)..."
before=$(wc -l < "$L" 2>/dev/null || echo 0); kubectl get secrets -A >/dev/null 2>&1; sleep 2; after=$(wc -l < "$L" 2>/dev/null || echo 0)
if [[ "$after" -gt "$before" ]]; then echo "  PASS: audit log grows on API activity ($before -> $after lines)"; PASS=$((PASS + 1)); else echo "  FAIL: audit log did not grow ($before -> $after lines)"; FAIL=$((FAIL + 1)); fi
summary
