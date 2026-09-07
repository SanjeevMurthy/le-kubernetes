# Q44. Istio: enforce STRICT mTLS in a namespace (solution)

## Steps

**1. See the starting state.** A namespace with no PeerAuthentication inherits the mesh default, which is `PERMISSIVE`.

```bash
kubectl get peerauthentication -A
kubectl exec -n mesh-out curl -c curl -- \
  curl -s -o /dev/null -w '%{http_code}\n' --max-time 5 http://httpbin.mesh-lab/get
# 200, over plain HTTP, from a pod with no sidecar
```

**2. Write one namespace-wide PeerAuthentication.**

```bash
cat <<'YAML' | kubectl apply -f -
apiVersion: security.istio.io/v1
kind: PeerAuthentication
metadata:
  name: default
  namespace: mesh-lab
spec:
  mtls:
    mode: STRICT
YAML
```

Two details decide whether this is namespace-wide. It must be in the namespace it governs, and it must have **no** `selector`. A `spec.selector.matchLabels` turns the same object into a workload-level policy that leaves every other workload permissive. Older Istio releases serve the same object as `security.istio.io/v1beta1`.

**3. Check both directions.** Give the sidecars a few seconds to pick the policy up.

```bash
kubectl get peerauthentication -n mesh-lab -o yaml | grep -A2 mtls

kubectl exec -n mesh-lab mesh-client -c client -- \
  curl -s -o /dev/null -w '%{http_code}\n' --max-time 5 http://httpbin.mesh-lab/get
# 200

kubectl exec -n mesh-out curl -c curl -- \
  curl -s -o /dev/null -w '%{http_code}\n' --max-time 5 http://httpbin.mesh-lab/get
# 000, and curl reports "Recv failure: Connection reset by peer"
```

The out-of-mesh call gives no HTTP status at all, because the connection is dropped during the TLS handshake and never becomes an HTTP exchange.

## Why

Istio's default is `PERMISSIVE` for a migration reason: a sidecar accepts both mutual TLS from other sidecars and plain text from anything else, so a mesh can be rolled out service by service without breaking the callers that have not been enrolled yet. That default is also the hole. Any Pod that can reach the Pod IP, from any namespace and with no identity at all, is served, and the workload behind the sidecar believes the request came from the mesh. `STRICT` closes it by requiring a peer certificate, which only a sidecar has.

The identity in that certificate is what makes the setting worth more than transport encryption. Istio issues each workload a SPIFFE identity derived from its ServiceAccount, `spiffe://<trust-domain>/ns/<namespace>/sa/<serviceaccount>`, and the sidecar verifies it on every connection. That is the identity an AuthorizationPolicy matches on in `source.principals`. Without `STRICT` those rules are advisory, because a caller that speaks plain text has no principal to match and, in permissive mode, still gets through.

The scope of the object is the part that is easy to get wrong under time pressure. A PeerAuthentication in the root namespace, usually `istio-system`, sets the mesh default. One in a workload namespace with no selector sets the namespace default, which is what this task asks for. One with a selector applies to the matching workloads only. Most specific wins, so a permissive workload-level policy quietly overrides a strict namespace-level one, and checking the effect rather than the object is the only way to catch that.

The test itself has to be built carefully. A `curl` that fails proves nothing on its own, because it fails just as convincingly when the Pod is gone, the image has no `curl`, or DNS is broken. The refusal only means mTLS is enforced once the same request has been shown to succeed from inside the mesh, and once the out-of-mesh Pod has been shown to reach something else. That is why the verifier makes those two calls first.

## Verify

```bash
kubectl -n mesh-lab get peerauthentication -o jsonpath='{.items[*].spec.mtls.mode}'   # STRICT

kubectl exec -n mesh-lab mesh-client -c client -- \
  curl -s -o /dev/null -w '%{http_code}\n' --max-time 5 http://httpbin.mesh-lab/get   # 200

kubectl exec -n mesh-out curl -c curl -- \
  curl -sk -o /dev/null -w '%{http_code}\n' --max-time 5 https://kubernetes.default.svc/healthz  # not 000

kubectl exec -n mesh-out curl -c curl -- \
  curl -s -o /dev/null -w '%{http_code}\n' --max-time 5 http://httpbin.mesh-lab/get   # not 200
```

## Docs

**Allowed:** `https://istio.io/latest/docs/` is an allowed source for the CKS exam. The two pages that matter here are the mutual TLS task under `https://istio.io/latest/docs/tasks/security/authentication/mtls-migration/` and the PeerAuthentication reference under `https://istio.io/latest/docs/reference/config/security/peer_authentication/`.

Worth memorising: the object shape (`kind: PeerAuthentication`, `spec.mtls.mode`), the three modes `STRICT`, `PERMISSIVE` and `DISABLE`, the three scopes (root namespace, namespace, selector) and their precedence, and the fact that a namespace-wide policy is the one without a `selector`.
