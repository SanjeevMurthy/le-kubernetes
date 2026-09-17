#!/bin/bash
# Q47 ValidatingAdmissionPolicy: verify. The object checks are secondary. What
# decides this question is whether the API server actually refuses a root Pod
# in vap-lab and still accepts one in vap-other, so the admission decision is
# tested directly with server-side dry runs, which evaluate policy without
# leaving Pods behind.
source "$(dirname "$0")/../../lib/checks.sh"
source "$(dirname "$0")/../../lib/env.sh"

POL=require-non-root
BIND=require-non-root-binding

echo "Checking the policy object..."
check "validatingadmissionpolicy/$POL exists" kubectl get validatingadmissionpolicy "$POL"
check_contains "it matches pods" "pods" \
  "$(kjp validatingadmissionpolicy "$POL" '' '{.spec.matchConstraints.resourceRules[*].resources[*]}')"
OPS=$(kjp validatingadmissionpolicy "$POL" '' '{.spec.matchConstraints.resourceRules[*].operations[*]}')
check_contains "it matches CREATE" "CREATE" "$OPS"
check_contains "it matches UPDATE" "UPDATE" "$OPS"
check_contains "the message is the one the task asked for" "every Pod must set runAsNonRoot: true" \
  "$(kjp validatingadmissionpolicy "$POL" '' '{.spec.validations[*].message}')"

echo "Checking the binding..."
check "validatingadmissionpolicybinding/$BIND exists" kubectl get validatingadmissionpolicybinding "$BIND"
check_eq "it binds $POL" "$POL" \
  "$(kjp validatingadmissionpolicybinding "$BIND" '' '{.spec.policyName}')"
check_contains "its validationActions include Deny" "Deny" \
  "$(kjp validatingadmissionpolicybinding "$BIND" '' '{.spec.validationActions[*]}')"

# ─── the part that actually decides the question ───────────────────
# dry_run_pod <label> <expect allow|deny> <namespace> <extra kubectl args...>
dry_run_pod() {
  local label="$1" expect="$2" ns="$3"; shift 3
  local out rc
  out=$(kubectl -n "$ns" run "vap-probe-$RANDOM" --image=nginx:1.27 --restart=Never \
        --dry-run=server "$@" 2>&1); rc=$?
  if [[ "$expect" == deny ]]; then
    if [[ $rc -ne 0 ]]; then
      echo "  PASS: $label"; PASS=$((PASS + 1))
    else
      echo "  FAIL: $label (it was admitted)"; FAIL=$((FAIL + 1))
    fi
  else
    if [[ $rc -eq 0 ]]; then
      echo "  PASS: $label"; PASS=$((PASS + 1))
    else
      echo "  FAIL: $label (it was refused: $(echo "$out" | tail -1))"; FAIL=$((FAIL + 1))
    fi
  fi
}

NONROOT='{"spec":{"securityContext":{"runAsNonRoot":true}}}'

echo "Checking what vap-lab now refuses..."
dry_run_pod "a Pod with no securityContext is refused in vap-lab" deny vap-lab
dry_run_pod "a Pod with runAsNonRoot: false is refused in vap-lab" deny vap-lab \
  --overrides='{"spec":{"securityContext":{"runAsNonRoot":false}}}'

echo "Checking what vap-lab still accepts..."
# This one comes after the refusals on purpose: if it fails, the policy is not
# merely present but is rejecting correct answers too, which is worse.
dry_run_pod "a Pod with runAsNonRoot: true is accepted in vap-lab" allow vap-lab \
  --overrides="$NONROOT"

echo "Checking the binding is scoped and has not leaked..."
dry_run_pod "a Pod with no securityContext is still accepted in vap-other" allow vap-other
dry_run_pod "a Pod with no securityContext is still accepted in default" allow default

echo "Checking the message reaches the user..."
MSG=$(kubectl -n vap-lab run vap-probe-msg --image=nginx:1.27 --restart=Never --dry-run=server 2>&1)
check_contains "the refusal quotes the required message" "every Pod must set runAsNonRoot: true" "$MSG"

summary
