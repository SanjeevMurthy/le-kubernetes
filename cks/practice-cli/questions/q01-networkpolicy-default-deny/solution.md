# Q1. NetworkPolicy: Default-Deny + Selective Allow (solution)

## Steps

Nothing here needs a node. Three policies, applied in an order that never leaves the namespace broken for long.

**1. Check the CNI enforces policy at all.** This is the first thing to establish and the easiest to skip. The default minikube CNI accepts NetworkPolicy objects and ignores them, so every policy you write appears to work and nothing is actually blocked.

```bash
kubectl get ds -n kube-system | grep -Ei 'calico|cilium|weave'
```

If that returns nothing, the answer will verify as correct YAML and deny no traffic.

**2. Default-deny both directions.** An empty `podSelector` selects every pod in the namespace; naming both policy types with no rules under them denies everything.

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny
  namespace: netpol-lab
spec:
  podSelector: {}
  policyTypes: ["Ingress", "Egress"]
EOF
```

Listing a type with no matching rule is what denies it. Leave `Egress` out of `policyTypes` and egress stays wide open no matter what else the file says.

**3. Re-allow DNS immediately.** Do this before anything else, because the policy you just applied has broken name resolution for every pod in the namespace, and a surprising number of later checks fail for that reason alone.

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns
  namespace: netpol-lab
spec:
  podSelector: {}
  policyTypes: ["Egress"]
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: kube-system
    ports:
    - protocol: UDP
      port: 53
    - protocol: TCP
      port: 53
EOF
```

Both protocols. DNS is UDP until a response exceeds 512 bytes, and then the resolver retries over TCP; allowing only UDP produces intermittent failures that look like anything but a policy.

**4. Allow frontend to reach backend on 8080.**

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-to-backend
  namespace: netpol-lab
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes: ["Ingress"]
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - protocol: TCP
      port: 8080
EOF
```

**5. Test the effect, in both directions.** Policies are additive and permissive: with several in play, reading the YAML is not a reliable way to know what is allowed.

```bash
# DNS must still work from anywhere in the namespace
kubectl -n netpol-lab run probe --rm -it --image=busybox:1.36 --restart=Never \
  -- nslookup kubernetes.default.svc.cluster.local

# frontend must reach backend
kubectl -n netpol-lab exec deploy/frontend -- wget -qO- --timeout=3 backend:8080

# anything else must not
kubectl -n netpol-lab run probe --rm -it --image=busybox:1.36 --restart=Never \
  -- wget -qO- --timeout=3 backend:8080
```

The last one should hang for its timeout and fail. A refusal that comes back instantly is usually DNS failing rather than the connection being dropped, which is a different bug.

## OR and AND, the rule that decides these questions

This is the part that is asked about indirectly and gets answered wrongly:

```yaml
  # TWO entries in the list: podSelector OR namespaceSelector
  - from:
    - podSelector:
        matchLabels: {app: frontend}
    - namespaceSelector:
        matchLabels: {team: web}
```

```yaml
  # ONE entry with two keys: podSelector AND namespaceSelector
  - from:
    - podSelector:
        matchLabels: {app: frontend}
      namespaceSelector:
        matchLabels: {team: web}
```

The difference is a single `-`. The first admits frontend pods from anywhere, plus every pod in a `team: web` namespace. The second admits only frontend pods that are also in a `team: web` namespace. When a question says "from pods labelled X **in** namespace Y", it means the second.

## Gotchas

- `podSelector: {}` means every pod in the namespace. A missing `podSelector` key is a different thing and is invalid.
- Policies only ever add permission. There is no deny rule and no ordering; the union of everything that selects a pod is what it gets.
- A default-deny egress breaks DNS. Every question in this family needs the DNS allow, whether or not it says so.
- `kubernetes.io/metadata.name` is a label the API server puts on every namespace, which is how to select `kube-system` without labelling it yourself.
- NetworkPolicy selects pods, never Services. Traffic to a Service IP is evaluated against the backing pod's labels and the **container** port, which is 8080 here, not a Service port.
- `ipBlock` cannot select in-cluster pods reliably and is for CIDRs outside the cluster, which is what Q24 uses it for against the metadata endpoint.

## Docs

`kubernetes.io/docs` is allowed and the page below carries a full set of copyable examples, including the default-deny pair. Knowing its title is worth more than memorising the schema.

- https://kubernetes.io/docs/concepts/services-networking/network-policies/
- https://kubernetes.io/docs/tasks/administer-cluster/declare-network-policy/
