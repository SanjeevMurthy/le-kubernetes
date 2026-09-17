# Q47. Require non-root Pods with a ValidatingAdmissionPolicy

**Host:** any host with `kubectl`.

Namespace `vap-lab` must refuse any Pod that does not declare itself non-root. The cluster has no policy engine installed and none may be installed: use the admission policy built into the API server.

1. Create a `ValidatingAdmissionPolicy` named `require-non-root` that matches `CREATE` and `UPDATE` on `pods` in the core API group, and rejects any Pod whose `spec.securityContext.runAsNonRoot` is not `true`. A Pod with no `securityContext` at all must be rejected too, not accepted by accident.

2. Give it the failure message `every Pod must set runAsNonRoot: true`.

3. Create a `ValidatingAdmissionPolicyBinding` named `require-non-root-binding` that binds the policy with `validationActions: ["Deny"]`, and scopes it to namespace `vap-lab` only.

Afterwards a Pod without `runAsNonRoot: true` must be refused in `vap-lab`, a Pod with it must be accepted there, and namespace `vap-other` must be unaffected.
