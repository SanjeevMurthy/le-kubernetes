# Q14. Restrict Images via ImagePolicyWebhook/Registry (solution)

**Concept & Explanation:**

`ImagePolicyWebhook` makes the apiserver consult an external service to allow/deny each image; it needs an `AdmissionConfiguration` file, a webhook kubeconfig, and the plugin enabled — plus volume mounts. Where no backend exists, a Kyverno `validate` policy enforces the same registry allow-list more simply.

**Solution — Step by Step:**

```yaml
# Option A — ImagePolicyWebhook
# /etc/kubernetes/admission/admission-config.yaml
apiVersion: apiserver.config.k8s.io/v1
kind: AdmissionConfiguration
plugins:
- name: ImagePolicyWebhook
  configuration:
    imagePolicy:
      kubeConfigFile: /etc/kubernetes/admission/webhook.kubeconfig
      allowTTL: 50
      denyTTL: 50
      retryBackoff: 500
      defaultAllow: false        # fail closed
```
```bash
# apiserver flags (back up first; add volumes/volumeMounts for /etc/kubernetes/admission):
#   --enable-admission-plugins=...,ImagePolicyWebhook
#   --admission-control-config-file=/etc/kubernetes/admission/admission-config.yaml
```
```yaml
# Option B — Kyverno allowed-registry (simpler, common)
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata: {name: allowed-registry}
spec:
  validationFailureAction: Enforce
  rules:
  - name: only-internal
    match: {any: [{resources: {kinds: [Pod]}}]}
    validate:
      message: "only registry.internal images allowed"
      pattern: {spec: {containers: [{image: "registry.internal/*"}]}}
```

**Key Points to Remember:**

- ImagePolicyWebhook = config file + webhook kubeconfig + apiserver flags + **volume mounts**; `defaultAllow: false` fails closed.
- Back up the apiserver manifest; a wrong path here breaks the control plane.
- Kyverno is the faster path when the task just says "restrict the registry."

**Official Documentation:**
- https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/#imagepolicywebhook
- https://kyverno.io/policies/

---
