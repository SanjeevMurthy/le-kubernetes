#!/bin/bash
# Q15 static analysis and manifest hardening: verify.
source "$(dirname "$0")/../../lib/checks.sh"
source "$(dirname "$0")/../../lib/env.sh"

NS=appsec
M="$COURSE_DIR/15/deploy.yaml"

jp() { kjp deploy app "$NS" "$1"; }

RORF=$(jp '{.spec.template.spec.containers[0].securityContext.readOnlyRootFilesystem}')
APE=$(jp '{.spec.template.spec.containers[0].securityContext.allowPrivilegeEscalation}')
DROP=$(jp '{.spec.template.spec.containers[0].securityContext.capabilities.drop[*]}')
NONROOT=$(jp '{.spec.template.spec.containers[0].securityContext.runAsNonRoot}')
[[ -z "$NONROOT" ]] && NONROOT=$(jp '{.spec.template.spec.securityContext.runAsNonRoot}')

echo "Checking the hardened Deployment in $NS..."
check_eq "readOnlyRootFilesystem is true" "true" "$RORF"
check_eq "allowPrivilegeEscalation is false" "false" "$APE"
check_contains "capabilities.drop contains ALL" "ALL" "$DROP"
check_eq "runAsNonRoot is true" "true" "$NONROOT"

echo "Checking the manifest deliverable..."
check "the manifest still exists at $M" test -s "$M"
check_file_has "the manifest itself was hardened, not just the live object" 'readOnlyRootFilesystem: *true' "$M"

if command -v kubesec >/dev/null 2>&1; then
  echo "Checking kubesec scores the hardened manifest above zero..."
  SCORE=$(kubesec scan "$M" 2>/dev/null | grep -Eo '"score": *-?[0-9]+' | head -1 | grep -Eo '\-?[0-9]+$')
  if [[ -n "$SCORE" && "$SCORE" -gt 0 ]]; then
    echo "  PASS: kubesec score is $SCORE (the original manifest scores 0 or less)"; PASS=$((PASS + 1))
  else
    echo "  FAIL: kubesec score is '${SCORE:-none}'; rerun kubesec scan $M and clear the advice"; FAIL=$((FAIL + 1))
  fi
else
  echo "  SKIP: kubesec is not installed, so the score check was not run"
fi

summary
