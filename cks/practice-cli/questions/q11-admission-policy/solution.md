# Q11. Admission Policy with Kyverno/Gatekeeper (solution)

**Concept & Explanation:**

Kyverno evaluates `ClusterPolicy` rules at admission through a validating webhook. A `validate` rule set to `Enforce` rejects the request; `Audit` only reports it. A pattern match on `image` restricts the allowed registry, the classic supply-chain admission control. The webhook also runs for `--dry-run=server`, which is how you test a policy without leaving pods behind.

**Solution — Step by Step:**

```bash
kubectl apply -f - <<'YAML'
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata: {name: restrict-registries}
spec:
  validationFailureAction: Enforce     # Kyverno 1.13+: validate.failureAction below
  background: false
  rules:
  - name: only-internal-registry
    match: {any: [{resources: {kinds: [Pod]}}]}
    validate:
      failureAction: Enforce
      message: "images must come from registry.internal/"
      pattern:
        spec:
          containers:
          - image: "registry.internal/*"
YAML

# Test both directions without creating anything
kubectl run bad  --image=docker.io/library/nginx:1.27 -n kyverno-lab --dry-run=server   # rejected
kubectl run good --image=registry.internal/nginx:1.27 -n kyverno-lab --dry-run=server   # admitted
```

**Key Points to Remember:**

- `Enforce` blocks, `Audit` only reports. Read which one the task asks for.
- Kyverno 1.13 moved the setting to `spec.rules[].validate.failureAction`; older releases use `spec.validationFailureAction`. Set the one your cluster's CRD accepts.
- Patterns take wildcards (`registry.internal/*`). Add `initContainers` and `ephemeralContainers` to the pattern when the task says all containers.
- A violating Deployment is still accepted; the rejection surfaces when its ReplicaSet creates pods, so read the events, not the Deployment.
- Verify by admission, not by reading YAML: `--dry-run=server` proves the webhook fires.

**Official Documentation:**
- https://kyverno.io/docs/ · https://kyverno.io/policies/
- https://open-policy-agent.github.io/gatekeeper/

---
