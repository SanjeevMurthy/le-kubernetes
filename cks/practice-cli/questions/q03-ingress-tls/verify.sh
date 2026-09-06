#!/bin/bash
# Q3 Ingress TLS: verify.
source "$(dirname "$0")/../../lib/checks.sh"
source "$(dirname "$0")/../../lib/env.sh"

NS=tls-lab
HOST=secure.example.com

echo "Checking the TLS secret and the ingress object..."
check_eq "secret web-tls is type kubernetes.io/tls" "kubernetes.io/tls" "$(kjp secret web-tls "$NS" '{.type}')"
check_eq "ingress web-ingress terminates TLS with web-tls" "web-tls" "$(kjp ingress web-ingress "$NS" '{.spec.tls[0].secretName}')"
check_contains "spec.tls covers host $HOST" "$HOST" "$(kjp ingress web-ingress "$NS" '{.spec.tls[*].hosts[*]}')"
check_contains "a rule routes host $HOST" "$HOST" "$(kjp ingress web-ingress "$NS" '{.spec.rules[*].host}')"
check_contains "the rule backs onto service web" "web" "$(kjp ingress web-ingress "$NS" '{.spec.rules[*].http.paths[*].backend.service.name}')"

# Where the ingress controller can be reached from this host: an external
# address if the service has one, else the node address, else the cluster IP
# (routable from a node).
ingress_endpoint() {
  local ns name ip port np
  read -r ns name <<<"$(kubectl get svc -A -o jsonpath='{range .items[*]}{.metadata.namespace}{" "}{.metadata.name}{"\n"}{end}' 2>/dev/null |
    awk '$2 ~ /ingress-nginx-controller$/ {print $1, $2; exit}')"
  [[ -n "$name" ]] || return 1
  port=443
  ip=$(kubectl get svc "$name" -n "$ns" -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
  if [[ -z "$ip" ]]; then
    ip=$(minikube ip -p cks 2>/dev/null || minikube ip 2>/dev/null)
    if [[ -n "$ip" ]]; then
      np=$(kubectl get svc "$name" -n "$ns" -o jsonpath='{.spec.ports[?(@.port==443)].nodePort}' 2>/dev/null)
      [[ -n "$np" ]] && port="$np"
    fi
  fi
  [[ -n "$ip" ]] || ip=$(kubectl get svc "$name" -n "$ns" -o jsonpath='{.spec.clusterIP}' 2>/dev/null)
  [[ -n "$ip" ]] || return 1
  echo "$ip $port"
}

echo "Checking HTTPS actually works through the ingress controller (effect test)..."
read -r EIP EPORT <<<"$(ingress_endpoint)"
if [[ -z "$EIP" ]]; then
  echo "  FAIL: could not find an ingress-nginx-controller service to send the request to"
  FAIL=$((FAIL + 1))
else
  CODE=$(curl -sk --max-time 15 --resolve "$HOST:$EPORT:$EIP" \
    "https://$HOST:$EPORT/" -o /dev/null -w '%{http_code}' 2>/dev/null)
  check_eq "curl https://$HOST via $EIP:$EPORT returns 200" 200 "$CODE"
fi

summary
