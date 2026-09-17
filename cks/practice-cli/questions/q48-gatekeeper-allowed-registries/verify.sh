#!/bin/bash
# Q48 Gatekeeper: verify. Gatekeeper is a webhook, so the only honest test is
# to put a Pod through admission and see what comes back. Server-side dry runs
# do that without creating anything or pulling an image.
source "$(dirname "$0")/../../lib/checks.sh"
source "$(dirname "$0")/../../lib/env.sh"

CON=allowed-registries
KIND=k8sallowedrepos

echo "Checking the constraint..."
check "$KIND/$CON still exists" kubectl get "$KIND" "$CON"
REPOS=$(kjp "$KIND" "$CON" '' '{.spec.parameters.repos[*]}')
check_contains "registry.k8s.io/ is allowed" "registry.k8s.io/" "$REPOS"
check_not "docker.io/ is no longer allowed" grep -q 'docker.io' <<<"$REPOS"
check_eq "exactly one repo is listed" 1 "$(wc -w <<<"$REPOS" | tr -d ' ')"

echo "Checking the scope and enforcement were left alone..."
check_eq "enforcement is still a hard deny" "deny" \
  "$(kjp "$KIND" "$CON" '' '{.spec.enforcementAction}')"
check_contains "it still matches only supply-lab" "supply-lab" \
  "$(kjp "$KIND" "$CON" '' '{.spec.match.namespaces[*]}')"
check_contains "it still matches Pods" "Pod" \
  "$(kjp "$KIND" "$CON" '' '{.spec.match.kinds[*].kinds[*]}')"
check "the ConstraintTemplate was not edited" kubectl get constrainttemplate k8sallowedrepos

# ─── the part that actually decides the question ───────────────────
# Gatekeeper reloads a changed constraint asynchronously, so a check run the
# instant after an edit can read the old policy. Wait for the new rule to be
# live before grading, rather than grading a race.
echo "Waiting for Gatekeeper to pick up the constraint..."
settled=no
for _ in $(seq 1 15); do
  if ! kubectl -n supply-lab run gk-settle --image=nginx:1.27 --restart=Never \
       --dry-run=server >/dev/null 2>&1; then
    settled=yes; break
  fi
  sleep 2
done
if [[ "$settled" == yes ]]; then
  echo "  PASS: the constraint is live and refusing Docker Hub"; PASS=$((PASS + 1))
else
  echo "  FAIL: after 30s a Docker Hub image is still admitted in supply-lab"; FAIL=$((FAIL + 1))
fi

# dry_run_pod <label> <expect allow|deny> <namespace> <image>
dry_run_pod() {
  local label="$1" expect="$2" ns="$3" img="$4" out rc
  out=$(kubectl -n "$ns" run "gk-probe-$RANDOM" --image="$img" --restart=Never \
        --dry-run=server 2>&1); rc=$?
  if [[ "$expect" == deny && $rc -ne 0 ]] || [[ "$expect" == allow && $rc -eq 0 ]]; then
    echo "  PASS: $label"; PASS=$((PASS + 1))
  elif [[ "$expect" == deny ]]; then
    echo "  FAIL: $label (it was admitted)"; FAIL=$((FAIL + 1))
  else
    echo "  FAIL: $label (it was refused: $(echo "$out" | tail -1))"; FAIL=$((FAIL + 1))
  fi
}

echo "Checking what supply-lab now refuses..."
dry_run_pod "a bare docker.io image is refused"      deny  supply-lab "nginx:1.27"
dry_run_pod "an explicit docker.io/ image is refused" deny supply-lab "docker.io/library/nginx:1.27"

echo "Checking what supply-lab still accepts..."
# After the refusals on purpose: a constraint that refuses everything, the
# allowed registry included, is not a pass.
dry_run_pod "a registry.k8s.io image is accepted" allow supply-lab "registry.k8s.io/pause:3.9"

echo "Checking the constraint is still scoped..."
dry_run_pod "supply-other is unaffected" allow supply-other "nginx:1.27"
dry_run_pod "default is unaffected"      allow default     "nginx:1.27"

summary
