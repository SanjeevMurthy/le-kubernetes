# Q47. Require non-root Pods with a ValidatingAdmissionPolicy (solution)

## Steps

Nothing here needs a node. Two objects are created and both are cluster-scoped.

**1. Write the policy.** A `ValidatingAdmissionPolicy` is two things: what it matches, and the CEL expressions that must all be true for the object to be admitted.

```bash
cat > vap.yaml <<'EOF'
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionPolicy
metadata:
  name: require-non-root
spec:
  failurePolicy: Fail
  matchConstraints:
    resourceRules:
    - apiGroups:   [""]
      apiVersions: ["v1"]
      operations:  ["CREATE", "UPDATE"]
      resources:   ["pods"]
  validations:
  - expression: >-
      has(object.spec.securityContext) &&
      has(object.spec.securityContext.runAsNonRoot) &&
      object.spec.securityContext.runAsNonRoot == true
    message: "every Pod must set runAsNonRoot: true"
EOF
kubectl apply -f vap.yaml
```

The two `has()` calls are the whole answer to "a Pod with no securityContext must be rejected too". CEL raises an error on a field that is not there, and under `failurePolicy: Fail` an erroring expression rejects the object, so the naive one-line version happens to behave correctly on this cluster and for the wrong reason. Ask whether the field exists first and the expression returns a plain `false`, which is what the message is for.

Note `apiGroups: [""]` with an empty string. Pods are in the core group, and writing `apiGroups: ["v1"]` is the usual slip: it matches nothing, the policy silently applies to nothing, and everything is admitted.

**2. Bind it, scoped to the one namespace.** A policy on its own does nothing at all. The binding is what turns it on, and `validationActions` is what decides whether a failure denies, warns, or only audits.

```bash
cat > vapb.yaml <<'EOF'
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionPolicyBinding
metadata:
  name: require-non-root-binding
spec:
  policyName: require-non-root
  validationActions: ["Deny"]
  matchResources:
    namespaceSelector:
      matchLabels:
        kubernetes.io/metadata.name: vap-lab
EOF
kubectl apply -f vapb.yaml
```

`kubernetes.io/metadata.name` is a label the API server maintains on every Namespace, set to the namespace's own name. It is the way to scope a binding to one namespace without labelling anything yourself.

**3. Prove it in both directions.** `--dry-run=server` sends the request through admission and throws the result away, so you can test a denial without creating anything and without waiting for an image pull.

```bash
# must be refused
kubectl -n vap-lab run probe --image=nginx:1.27 --dry-run=server

# must be accepted
kubectl -n vap-lab run probe --image=nginx:1.27 --dry-run=server \
  --overrides='{"spec":{"securityContext":{"runAsNonRoot":true}}}'

# must still be accepted: the binding is scoped to vap-lab
kubectl -n vap-other run probe --image=nginx:1.27 --dry-run=server
```

The first should print the message you wrote:

```
Error from server (Forbidden): pods "probe" is forbidden: ValidatingAdmissionPolicy 'require-non-root' with binding 'require-non-root-binding' denied request: every Pod must set runAsNonRoot: true
```

## Why this and not Kyverno or Gatekeeper

`ValidatingAdmissionPolicy` is part of the API server. Nothing to install, nothing to keep running, no webhook that can time out and take admission down with it. That also makes it the one admission mechanism you can rely on being available in an exam cluster, and the only one whose documentation is on `kubernetes.io`, which is an allowed domain. Kyverno's and Gatekeeper's are not.

The trade is expressiveness. CEL evaluates against the object in front of it and cannot look anything else up, so "no two Ingresses may claim the same host" is a Kyverno or Gatekeeper job. "This field must have this value" is exactly what CEL is for, and that is most of what the exam asks. Q11 does the same class of task with Kyverno and Q48 with Gatekeeper; this is the one that needs no installation.

## Gotchas

- A policy with no binding enforces nothing, and `kubectl get validatingadmissionpolicy` looks perfectly healthy. If a denial is not happening, check the binding first.
- Leaving `validationActions` out defaults to `["Deny"]` on many builds, but write it: the task asked for it, and `["Audit"]` or `["Warn"]` produces an object that looks right and refuses nothing.
- `apiGroups: [""]` for core resources. Not `["v1"]`, not `["core"]`.
- CEL errors on absent fields. Use `has()`, or `object.spec.?securityContext.?runAsNonRoot.orValue(false)` if you prefer optionals. Do not rely on the error path to do your rejecting.
- The object is `object`; the previous one on an update is `oldObject`. Both are the raw API object, so it is `object.spec.containers`, not a Pod helper of any kind.
- Existing Pods are never re-evaluated. `legacy-root` keeps running after the policy is in place, exactly as it does under Pod Security Admission. Admission control is about what is being created, and the question of what is already running is Q36's.
- `spec.securityContext.runAsNonRoot` is the Pod-level field. A container-level `runAsNonRoot` is a different path, and a policy that only checks one of them is easy to slip past.

## Docs

`kubernetes.io/docs` is allowed in the exam and covers all of this, including a page of ready-made CEL examples worth knowing how to find.

- https://kubernetes.io/docs/reference/access-authn-authz/validating-admission-policy/
- https://kubernetes.io/docs/reference/using-api/cel/
- `kubectl explain validatingadmissionpolicy.spec.validations` when the browser is slower than the terminal
