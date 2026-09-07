#!/bin/bash
# Q35 Cilium L7: verify. The graded facts are the shape of the policy and, more
# importantly, that a denied request comes back as 403 rather than timing out.
source "$(dirname "$0")/../../lib/checks.sh"
source "$(dirname "$0")/../../lib/env.sh"

NS=cilium-lab
CNP=ciliumnetworkpolicies.cilium.io

# The policy may carry any name, so find it by what it selects. Cilium keeps the
# spec as it was authored, but accept the "any:" label prefix too in case the
# candidate wrote it that way.
sel() { kjp "$CNP" "$1" "$NS" "$2"; }

POL=""
for p in $(kubectl get "$CNP" -n "$NS" -o jsonpath='{.items[*].metadata.name}' 2>/dev/null); do
  a=$(sel "$p" '{.spec.endpointSelector.matchLabels.app}')
  [[ -z "$a" ]] && a=$(sel "$p" '{.spec.endpointSelector.matchLabels.any\:app}')
  if [[ "$a" == "api" ]]; then POL="$p"; break; fi
done

echo "Checking the CiliumNetworkPolicy in namespace $NS..."
check "a CiliumNetworkPolicy selects the api pods (app=api)" test -n "$POL"
echo "  (checking policy '${POL:-<none found>}')"

FROM=$(sel "$POL" '{.spec.ingress[0].fromEndpoints[0].matchLabels.app}')
[[ -z "$FROM" ]] && FROM=$(sel "$POL" '{.spec.ingress[0].fromEndpoints[0].matchLabels.any\:app}')
check_eq "ingress is allowed from the client pods only" "client" "$FROM"
check_eq "the rule is scoped to port 80" "80" "$(sel "$POL" '{.spec.ingress[0].toPorts[0].ports[0].port}')"
check_eq "the L7 rule allows the GET method" "GET" "$(sel "$POL" '{.spec.ingress[0].toPorts[0].rules.http[0].method}')"
check_eq "the L7 rule allows the path /health" "/health" "$(sel "$POL" '{.spec.ingress[0].toPorts[0].rules.http[0].path}')"

echo "Checking both workloads are still up..."
check "deployment api rolled out" kubectl -n "$NS" rollout status deploy/api --timeout=90s
check "deployment client rolled out" kubectl -n "$NS" rollout status deploy/client --timeout=90s

echo "Effect test: the rejection has to be L7, not L3 or L4..."
code() {
  kubectl exec -n "$NS" deploy/client -- \
    curl -s -o /dev/null -m 10 -w '%{http_code}' "$1" 2>/dev/null
}
# Control case first. A policy that drops everything would also stop /anything,
# so the allowed path has to be proved working before the denial means anything.
check_eq "GET /health still returns 200 through the proxy" "200" "$(code http://api/health)"
# 403 is produced by the Cilium proxy. A curl timeout reports 000 here, which is
# what an L3 or L4 deny looks like and is not the answer to this question.
check_eq "GET /anything is refused with 403 by the proxy" "403" "$(code http://api/anything)"

summary
