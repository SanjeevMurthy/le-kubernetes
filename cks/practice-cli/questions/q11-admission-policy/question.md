# Q11. Admission Policy with Kyverno/Gatekeeper

Using Kyverno (already installed), create a `ClusterPolicy` that blocks any Pod whose container image does not come from `registry.internal/`. The policy must enforce (reject), not just audit.
