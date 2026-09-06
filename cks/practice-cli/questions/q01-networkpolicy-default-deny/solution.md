# Q1. NetworkPolicy: Default-Deny + Selective Allow (solution)

**Concept & Explanation:**

NetworkPolicies are additive, namespaced allow-lists enforced by the CNI (Calico/Cilium). An empty `podSelector: {}` selects all pods; a policy listing a `policyType` with no rules denies that whole direction. Because a default-deny egress also blocks DNS (UDP/TCP 53 to kube-dns), you must explicitly re-allow it — the single most common NetworkPolicy mistake.

**Solution — Step by Step:**

```bash
kubectl apply -f - <<'EOF'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata: {name: default-deny-all, namespace: netpol-lab}
spec:
  podSelector: {}
  policyTypes: [Ingress, Egress]
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata: {name: allow-frontend-to-backend, namespace: netpol-lab}
spec:
  podSelector: {matchLabels: {app: backend}}
  policyTypes: [Ingress]
  ingress:
  - from:
    - podSelector: {matchLabels: {app: frontend}}
    ports:
    - {port: 8080, protocol: TCP}
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata: {name: allow-dns, namespace: netpol-lab}
spec:
  podSelector: {}
  policyTypes: [Egress]
  egress:
  - to:
    - namespaceSelector: {}
    ports:
    - {port: 53, protocol: UDP}
    - {port: 53, protocol: TCP}
EOF
```

**Key Points to Remember:**

- Default-deny egress **breaks DNS** unless you allow port 53 UDP **and** TCP — always add the DNS rule.
- `podSelector: {}` = all pods in the namespace; omit a `policyType` and that direction is unaffected.
- Verify with a probe pod: `kubectl exec` a curl into `backend:8080` from `frontend` (allowed) vs another pod (denied).

**Official Documentation:**
- https://kubernetes.io/docs/concepts/services-networking/network-policies/

---
