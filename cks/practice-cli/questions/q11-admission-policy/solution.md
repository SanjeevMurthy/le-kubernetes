# Q11. Admission Policy with Kyverno/Gatekeeper (solution)

## Steps

Kyverno is already installed. Nothing here installs it, and an exam question in this family never asks you to.

**1. Check it is actually running** before writing a policy that will appear to do nothing.

```bash
kubectl -n kyverno get pods
kubectl get crd | grep kyverno
```

**2. Write the ClusterPolicy.**

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: restrict-registries
spec:
  validationFailureAction: Enforce
  background: false
  rules:
  - name: only-internal-registry
    match:
      any:
      - resources:
          kinds:
          - Pod
    validate:
      message: "images must come from registry.internal/"
      pattern:
        spec:
          containers:
          - image: "registry.internal/*"
EOF
```

Three fields carry the whole answer:

- `validationFailureAction: Enforce` is what rejects the request. The default is `Audit`, which admits the Pod and records a PolicyReport, and a policy left on the default passes every YAML inspection while blocking nothing. Capital `E`; older versions used `enforce` and newer ones reject the lowercase spelling.
- `pattern` with `registry.internal/*` is Kyverno's glob matching, not a regular expression. `*` matches within a path segment and `?` matches one character.
- `background: false` stops Kyverno scanning existing resources against this rule. Existing Pods are not the question, and leaving it on generates noisy reports.

**3. Confirm the policy loaded and is ready.** Kyverno compiles policies asynchronously, so a check run immediately after `apply` can race.

```bash
kubectl get clusterpolicy restrict-registries
```

```
NAME                  ADMISSION   BACKGROUND   VALIDATE ACTION   READY
restrict-registries   true        false        Enforce           True
```

`READY: True` is the thing to wait for. If it stays `False`, read `kubectl describe clusterpolicy restrict-registries` for the compile error.

**4. Test both directions.** `--dry-run=server` goes through admission and creates nothing.

```bash
# must be rejected
kubectl -n kyverno-lab run bad --image=docker.io/library/nginx:1.27 --dry-run=server

# must be accepted
kubectl -n kyverno-lab run good --image=registry.internal/nginx:1.27 --dry-run=server
```

The rejection quotes your own message:

```
Error from server: admission webhook "validate.kyverno.svc-fail" denied the request:
resource Pod/kyverno-lab/bad was blocked due to the following policies

restrict-registries:
  only-internal-registry: 'validation error: images must come from registry.internal/'
```

## validate, mutate, generate

Kyverno rules come in three kinds and the exam only ever asks for the first, but knowing the others exist stops you reaching for the wrong one:

- `validate` — accept or reject. This question.
- `mutate` — rewrite the object as it is admitted, for example adding a `securityContext` that was missing.
- `generate` — create a companion object, for example a default NetworkPolicy in every new namespace.

## Gotchas

- `validationFailureAction: Enforce` with a capital E. Without it the policy audits and admits, which is the single most common way this question is failed.
- `pattern` is glob, not regex. `registry.internal/*` is right; `^registry\.internal/.*$` is not.
- A bare `nginx:1.27` is `docker.io/library/nginx:1.27`. Testing with a short name and seeing it rejected is the rule working, not a bug.
- The rule matches `spec.containers` only. `initContainers` and `ephemeralContainers` are separate paths, and a question that asks about "all containers" needs them listed too.
- Never install or upgrade Kyverno as part of an answer. If it is not running, that is the finding to report, not a task to do.
- Kyverno's documentation is **not** on the exam's allowed list. The API shape has to come from memory or from the cluster: `kubectl explain clusterpolicy.spec` and `kubectl get clusterpolicy -o yaml` both work with no browser.

## The same job, three ways

This kit drills all three mechanisms, because which one a question wants is usually implied rather than stated:

| Question | Mechanism | Installed? | Docs allowed? |
|---|---|---|---|
| Q11 | Kyverno `ClusterPolicy` | must already be there | no |
| Q48 | Gatekeeper `Constraint` | must already be there | no |
| Q47 | `ValidatingAdmissionPolicy` | built into the API server | **yes** |

When a question leaves the mechanism open, Q47's is the one to reach for: nothing to install, and `kubernetes.io/docs` is on the allowed list.

## Docs

- `kubectl explain clusterpolicy.spec.rules` and `kubectl get clusterpolicy -o yaml` on the cluster itself
- https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/ for how the admission webhook Kyverno registers actually fits in (allowed)
