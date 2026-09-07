# Q35. CiliumNetworkPolicy: allow only GET /health (solution)

## Steps

**1. See what the client can reach today.**

```bash
kubectl exec -n cilium-lab deploy/client -- curl -s -o /dev/null -w '%{http_code}\n' http://api/health
kubectl exec -n cilium-lab deploy/client -- curl -s -o /dev/null -w '%{http_code}\n' http://api/anything
```

`200` and `404`. The `404` comes from nginx, not from a policy: nothing is filtered yet.

**2. Write the policy.** The API group is `cilium.io/v2` and the kind is `CiliumNetworkPolicy`, not `NetworkPolicy`.

```bash
vim l7.yaml
```

```yaml
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: api-l7
  namespace: cilium-lab
spec:
  endpointSelector:
    matchLabels:
      app: api
  ingress:
  - fromEndpoints:
    - matchLabels:
        app: client
    toPorts:
    - ports:
      - port: "80"
        protocol: TCP
      rules:
        http:
        - method: GET
          path: /health
```

Three details are worth naming, because each of them is a way to lose the marks:

- `port` is a **string**. `port: 80` is rejected by the CRD schema.
- `rules.http` sits under the port entry in `toPorts`, not under `ingress`. Put it one level too high and the policy applies at L4 only.
- `endpointSelector` replaces the `podSelector` of a core NetworkPolicy, and an empty `{}` would select every pod in the namespace.

**3. Apply it and watch the endpoints pick it up.**

```bash
kubectl apply -f l7.yaml
kubectl get cnp -n cilium-lab
```

**4. Test both paths.**

```bash
kubectl exec -n cilium-lab deploy/client -- curl -s -o /dev/null -w '%{http_code}\n' http://api/health     # 200
kubectl exec -n cilium-lab deploy/client -- curl -s -o /dev/null -w '%{http_code}\n' http://api/anything   # 403
```

If the second one hangs and finally prints `000`, the request never reached the proxy. That means the `toPorts` entry is missing or the port does not match, so Cilium is denying at L4 and dropping the packet instead of answering.

If the second one returns `404`, the L7 block was not parsed as an HTTP rule and everything is being allowed at L4. Check the indentation of `rules:` under the port.

## Why

A core `NetworkPolicy` can only reason about addresses and ports. It has no idea what an HTTP request is, so "allow this client to call one endpoint of this service" cannot be expressed in it at all. Cilium adds `rules.http` inside `toPorts`, and when a policy carries one, Cilium redirects that traffic through an Envoy proxy running in the datapath. The proxy parses the request, matches it against the rules, and forwards or refuses it.

The visible consequence is the status code. An L3 or L4 denial happens in the kernel datapath: the packet is dropped, the client gets nothing back, and `curl` sits there until its timeout. An L7 denial happens after a TCP connection has been established and the request has been parsed, so the proxy can and does answer, with `403 Access denied`. When a task says the client must be told no rather than left hanging, that is the signal to reach for an L7 rule.

`method` and `path` are regular expressions, matched against the whole value. `path: /health` therefore matches `/health` and nothing else, and `path: /health.*` would be needed to also allow `/healthz`. Leaving both fields out allows any request on that port, which turns the policy back into an L4 policy.

One general rule carries over from core NetworkPolicy: as soon as any ingress rule selects an endpoint, that endpoint is default-deny for ingress. So this single policy both opens `GET /health` for `client` and closes everything else to everyone, without a separate deny rule.

## Verify

```bash
kubectl get cnp -n cilium-lab -o yaml | head -40
kubectl exec -n cilium-lab deploy/client -- curl -s -o /dev/null -w '%{http_code}\n' http://api/health     # 200
kubectl exec -n cilium-lab deploy/client -- curl -s -o /dev/null -w '%{http_code}\n' http://api/anything   # 403
```

On a node, `cilium monitor --type drop` and `cilium policy get` show the same story from the datapath side, but they are not needed to answer the question.

## Docs

**Allowed:** `https://docs.cilium.io/en/stable` and, inside it, Policy then Layer 7 Examples. That page carries a complete `CiliumNetworkPolicy` with an `http` rule that can be copied and edited, which is the fastest route under exam time.

What has to be memorised is the outline, because finding it takes longer than typing it: `apiVersion: cilium.io/v2`, `endpointSelector`, `ingress[].fromEndpoints[].matchLabels`, `toPorts[].ports[].port` as a string, and `toPorts[].rules.http[]` with `method` and `path`.
