# Q11. Admission Policy with Kyverno/Gatekeeper

Kyverno is already installed in this cluster. Namespace `kyverno-lab` is empty and currently accepts pods from any registry.

1. Create a Kyverno `ClusterPolicy` named `restrict-registries` that blocks any Pod whose container image does not come from `registry.internal/`.
2. The policy must enforce, that is reject the request, not merely audit it.
3. Confirm the effect in `kyverno-lab`: `kubectl run bad --image=docker.io/library/nginx:1.27 --dry-run=server` must be rejected, and `kubectl run good --image=registry.internal/nginx:1.27 --dry-run=server` must be accepted.
