#!/bin/bash
# Q1 NetworkPolicy default-deny plus selective allow: verify.
source "$(dirname "$0")/../../lib/checks.sh"
source "$(dirname "$0")/../../lib/env.sh"

NS=netpol-lab
deny=0; allow=0; dns=0

np() { kjp networkpolicy "$1" "$NS" "$2"; }

for p in $(kubectl get networkpolicy -n "$NS" -o jsonpath='{.items[*].metadata.name}' 2>/dev/null); do
  # An empty podSelector selects every pod. Test it by the absence of selector
  # terms rather than by the serialised form of the empty map, which differs
  # between kubectl output modes.
  mk=$(np "$p" '{.spec.podSelector.matchLabels}')
  me=$(np "$p" '{.spec.podSelector.matchExpressions}')
  types=$(np "$p" '{.spec.policyTypes[*]}')
  if [[ -z "$mk" && -z "$me" && "$types" == *Ingress* && "$types" == *Egress* ]]; then deny=1; fi
  if [[ "$(np "$p" '{.spec.podSelector.matchLabels.app}')" == "backend" ]]; then
    from=$(np "$p" '{.spec.ingress[*].from[*].podSelector.matchLabels.app}')
    ports=$(np "$p" '{.spec.ingress[*].ports[*].port}')
    if [[ " $from " == *" frontend "* && " $ports " == *" 8080 "* ]]; then allow=1; fi
  fi
  if [[ " $(np "$p" '{.spec.egress[*].ports[*].port}') " == *" 53 "* ]]; then dns=1; fi
done

echo "Checking the policy objects in $NS..."
check_eq "a default-deny policy has an empty podSelector and both policyTypes" 1 "$deny"
check_eq "backend accepts ingress from frontend on TCP 8080" 1 "$allow"
check_eq "an egress rule allows DNS on port 53" 1 "$dns"

echo "Checking the workloads survived the policies..."
bpod=$(kubectl get pod -n "$NS" -l app=backend -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
fpod=$(kubectl get pod -n "$NS" -l app=frontend -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
check_pod_running "backend pod ${bpod:-<missing>} is Running" "$bpod" "$NS"
check_pod_running "frontend pod ${fpod:-<missing>} is Running" "$fpod" "$NS"

echo "Checking DNS still resolves from inside the namespace (effect test)..."
kubectl delete pod np-dns-check -n "$NS" --ignore-not-found >/dev/null 2>&1
check "nslookup kubernetes.default succeeds under the policies" \
  kubectl run np-dns-check -n "$NS" --rm -i --restart=Never --image=busybox:1.36 \
  --pod-running-timeout=90s -- nslookup kubernetes.default.svc.cluster.local

summary
