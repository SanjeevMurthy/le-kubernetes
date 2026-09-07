#!/bin/bash
# Q44 Istio mTLS: verify. The refusal only means something once the same request
# has been shown to work from inside the mesh, so the controls come first.
source "$(dirname "$0")/../../lib/checks.sh"
source "$(dirname "$0")/../../lib/env.sh"

NS=mesh-lab
OUT=mesh-out
URL="http://httpbin.$NS/get"

echo "Checking the PeerAuthentication..."
check "at least one PeerAuthentication exists in $NS" \
  bash -c "kubectl -n $NS get peerauthentication -o name | grep -q ."
MODES=$(kubectl -n "$NS" get peerauthentication -o jsonpath='{.items[*].spec.mtls.mode}' 2>/dev/null)
check_contains "a PeerAuthentication in $NS sets mtls.mode STRICT" STRICT "$MODES"

echo "Checking the mesh is really a mesh..."
HPOD=$(kubectl get pod -n "$NS" -l app=httpbin -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
check_pod_running "the httpbin pod ${HPOD:-<missing>} is Running" "$HPOD" "$NS"
check_contains "the httpbin pod has an istio-proxy sidecar" istio-proxy \
  "$(kjp pod "$HPOD" "$NS" '{.spec.containers[*].name}')"

# code <pod> <namespace> <container> <url> [curl flags...]
code() {
  local pod="$1" ns="$2" c="$3" url="$4"; shift 4
  kubectl exec -n "$ns" "$pod" -c "$c" -- \
    curl -s -o /dev/null -w '%{http_code}' --max-time 5 "$@" "$url" 2>/dev/null | tr -d '[:space:]'
}

echo "Control test: the same request from inside the mesh still works..."
IN=$(code mesh-client "$NS" client "$URL")
check_eq "pod/mesh-client in $NS gets 200 from $URL" 200 "$IN"

echo "Control test: the pod outside the mesh can still make requests at all..."
# Without this, a curl that fails because the pod is gone or the image has no
# curl would make the effect test below a PASS for the wrong reason.
OUTAPI=$(code curl "$OUT" curl "https://kubernetes.default.svc/healthz" -k)
if [[ -n "$OUTAPI" && "$OUTAPI" != "000" ]]; then
  echo "  PASS: pod/curl in $OUT reaches the API server service (HTTP $OUTAPI), so curl and DNS work"; PASS=$((PASS + 1))
else
  echo "  FAIL: pod/curl in $OUT could not reach anything (got '${OUTAPI:-no answer}'), so nothing below can be trusted"; FAIL=$((FAIL + 1))
  echo ""; echo "Results: $PASS passed, $FAIL failed"; exit 1
fi

echo "Effect test: plain text from outside the mesh is refused..."
OUTCODE=$(code curl "$OUT" curl "$URL")
if [[ "$OUTCODE" == "200" ]]; then
  echo "  FAIL: pod/curl in $OUT still gets 200 from $URL, so mTLS is not enforced"; FAIL=$((FAIL + 1))
else
  echo "  PASS: pod/curl in $OUT does not get 200 from $URL (got '${OUTCODE:-connection refused}')"; PASS=$((PASS + 1))
fi

summary
