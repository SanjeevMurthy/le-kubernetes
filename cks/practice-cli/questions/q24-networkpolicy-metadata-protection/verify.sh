#!/bin/bash
# Q24 metadata endpoint: Verify
source "$(dirname "$0")/../../lib/checks.sh"
source "$(dirname "$0")/../../lib/env.sh"

NS=metadata-lab

# Accept any policy in the namespace that carries an egress ipBlock rule, so a
# correct answer under a different name still scores.
POLICY=""
for p in $(kubectl get networkpolicy -n "$NS" -o jsonpath='{.items[*].metadata.name}' 2>/dev/null); do
  if [[ -n "$(kjp networkpolicy "$p" "$NS" '{.spec.egress[*].to[*].ipBlock.cidr}')" ]]; then
    POLICY="$p"
    break
  fi
done

echo "Checking the NetworkPolicy in namespace $NS..."
check "a NetworkPolicy with an egress ipBlock rule exists" test -n "$POLICY"
echo "  (checking policy '${POLICY:-<none found>}')"

check_contains "policyTypes contains Egress" Egress \
  "$(kjp networkpolicy "$POLICY" "$NS" '{.spec.policyTypes[*]}')"
check_eq "the podSelector matches the app pods (app=app)" app \
  "$(kjp networkpolicy "$POLICY" "$NS" '{.spec.podSelector.matchLabels.app}')"
check_contains "the egress rule allows the whole internet (0.0.0.0/0)" "0.0.0.0/0" \
  "$(kjp networkpolicy "$POLICY" "$NS" '{.spec.egress[*].to[*].ipBlock.cidr}')"
check_contains "the metadata address is excepted (169.254.169.254/32)" "169.254.169.254/32" \
  "$(kjp networkpolicy "$POLICY" "$NS" '{.spec.egress[*].to[*].ipBlock.except[*]}')"

echo "Checking the workload survived the policy..."
POD=$(kubectl get pod -n "$NS" -l app=app -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
check_pod_running "pod ${POD:-<missing>} is still Running" "$POD" "$NS"

# The probe carries app=app, so the policy applies to it. A policy that blocked
# everything rather than just the metadata address would fail here.
echo "Effect test: ordinary egress from a selected pod still works..."
kubectl delete pod np-meta-check -n "$NS" --ignore-not-found >/dev/null 2>&1
check "a pod labelled app=app can still resolve DNS under the policy" \
  kubectl run np-meta-check -n "$NS" --rm -i --restart=Never --image=busybox:1.36 \
  --labels=app=app --pod-running-timeout=90s -- nslookup kubernetes.default.svc.cluster.local

summary
