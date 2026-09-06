#!/bin/bash
# Q1 — NetworkPolicy default-deny + selective allow: Verify
PASS=0; FAIL=0
NS=prod
deny=0; allow=0; dns=0

get() { kubectl get networkpolicy "$1" -n "$NS" -o jsonpath="$2" 2>/dev/null; }

for p in $(kubectl get networkpolicy -n "$NS" -o jsonpath='{.items[*].metadata.name}' 2>/dev/null); do
  # An empty podSelector selects every pod. Test it by absence of selector terms rather than by
  # the serialised form of the empty map, which differs between kubectl output modes.
  mk=$(get "$p" '{.spec.podSelector.matchLabels}')
  me=$(get "$p" '{.spec.podSelector.matchExpressions}')
  types=$(get "$p" '{.spec.policyTypes[*]}')
  if [[ -z "$mk" && -z "$me" && "$types" == *Ingress* && "$types" == *Egress* ]]; then deny=1; fi
  if [[ "$(get "$p" '{.spec.podSelector.matchLabels.app}')" == "backend" ]]; then
    from=$(get "$p" '{.spec.ingress[*].from[*].podSelector.matchLabels.app}')
    ports=$(get "$p" '{.spec.ingress[*].ports[*].port}')
    if [[ " $from " == *" frontend "* && " $ports " == *" 8080 "* ]]; then allow=1; fi
  fi
  if [[ " $(get "$p" '{.spec.egress[*].ports[*].port}') " == *" 53 "* ]]; then dns=1; fi
done

echo "Checking a default-deny policy (Ingress+Egress, empty podSelector)..."
if [[ $deny -eq 1 ]]; then
  echo "  PASS: default-deny ingress+egress present"; ((PASS++))
else
  echo "  FAIL: no policy with an empty podSelector and both policyTypes"; ((FAIL++))
fi

echo "Checking backend accepts ingress from frontend on TCP 8080..."
if [[ $allow -eq 1 ]]; then
  echo "  PASS: backend <- frontend :8080 allowed"; ((PASS++))
else
  echo "  FAIL: missing allow rule (backend <- frontend :8080)"; ((FAIL++))
fi

echo "Checking an egress rule allows DNS (port 53)..."
if [[ $dns -eq 1 ]]; then
  echo "  PASS: DNS egress (53) allowed"; ((PASS++))
else
  echo "  FAIL: no egress rule for port 53 — DNS would break"; ((FAIL++))
fi

echo "Checking DNS actually resolves from inside the namespace (effect test)..."
if kubectl run np-dns-check -n "$NS" --rm -i --restart=Never --image=busybox:1.36 \
     --pod-running-timeout=90s -- nslookup kubernetes.default.svc.cluster.local >/dev/null 2>&1; then
  echo "  PASS: nslookup succeeded under the policies"; ((PASS++))
else
  echo "  FAIL: nslookup failed — egress to kube-dns on UDP/TCP 53 is blocked"; ((FAIL++))
fi

echo ""; echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
