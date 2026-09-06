# Q11. Admission Policy with Kyverno/Gatekeeper (solution)

**Concept & Explanation:**

Kyverno evaluates `ClusterPolicy` rules at admission. A `validate` rule with `validationFailureAction: Enforce` rejects violating resources. A pattern match on `image` restricts the allowed registry — a common supply-chain/admission control.

**Solution — Step by Step:**

```bash
kubectl apply -f - <<'EOF'
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata: {name: restrict-registries}
spec:
  validationFailureAction: Enforce
  background: false
  rules:
  - name: only-internal-registry
    match: {any: [{resources: {kinds: [Pod]}}]}
    validate:
      message: "images must come from registry.internal/"
      pattern:
        spec:
          containers:
          - image: "registry.internal/*"
EOF

# Test: should be REJECTED
kubectl run bad --image=nginx
# Should be ADMITTED
kubectl run ok --image=registry.internal/nginx:1.27
```

**Key Points to Remember:**

- `validationFailureAction: Enforce` blocks; `Audit` only reports — read which the task wants.
- Patterns support wildcards (`registry.internal/*`); apply to `initContainers`/`ephemeralContainers` too if asked.
- Verify by applying a violating pod and confirming rejection.

**Official Documentation:**
- https://kyverno.io/docs/ · https://kyverno.io/policies/
- https://open-policy-agent.github.io/gatekeeper/

---
