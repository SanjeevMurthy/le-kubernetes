# Q48. Gatekeeper: allow images from one registry only (solution)

## Steps

Read before you edit. The task names a constraint, and the fastest way to get this wrong is to edit the template instead.

**1. Find what is there.** Gatekeeper's objects are ordinary CRDs, so `kubectl get` finds them.

```bash
kubectl get constrainttemplates
kubectl get constraints                     # every constraint, whatever its kind
kubectl get k8sallowedrepos allowed-registries -o yaml
```

The interesting part is `spec.parameters.repos`:

```yaml
spec:
  enforcementAction: deny
  match:
    kinds:
    - apiGroups: [""]
      kinds: ["Pod"]
    namespaces: ["supply-lab"]
  parameters:
    repos:
    - "docker.io/"
    - "registry.k8s.io/"
```

**2. Remove the entry that should not be there.** The whole change is deleting one list item.

```bash
kubectl edit k8sallowedrepos allowed-registries
```

Leaving:

```yaml
  parameters:
    repos:
    - "registry.k8s.io/"
```

A patch does it without an editor, which is quicker and cannot leave you in vim with a broken document:

```bash
kubectl patch k8sallowedrepos allowed-registries --type merge \
  -p '{"spec":{"parameters":{"repos":["registry.k8s.io/"]}}}'
```

Use `--type merge` here. A strategic merge patch does not apply to custom resources, and a JSON patch would need the exact list index.

**3. Prove it, in both directions.**

```bash
# must be refused: bare nginx resolves to Docker Hub
kubectl -n supply-lab run probe --image=nginx:1.27 --dry-run=server

# must be accepted
kubectl -n supply-lab run probe --image=registry.k8s.io/pause:3.9 --dry-run=server

# must still be accepted: the constraint only matches supply-lab
kubectl -n supply-other run probe --image=nginx:1.27 --dry-run=server
```

The refusal quotes the rego's own message, which is how you tell a Gatekeeper denial from any other:

```
Error from server (Forbidden): admission webhook "validation.gatekeeper.sh" denied the request:
[allowed-registries] container <probe> has an invalid image repo <nginx:1.27>,
allowed repos are ["registry.k8s.io/"]
```

**4. If nothing is being refused,** look at the constraint's own status before doubting the edit. Gatekeeper records what it has actually loaded, and a rego compile error shows up here rather than on the `kubectl edit`:

```bash
kubectl get k8sallowedrepos allowed-registries -o jsonpath='{.status}' | yq -P
kubectl get constrainttemplate k8sallowedrepos -o jsonpath='{.status}' | yq -P
```

`status.byPod[].enforced: true` means every Gatekeeper replica has it.

## Template and constraint

Two objects, and the split is the thing to have straight before the exam:

- The **ConstraintTemplate** holds the rego. It is the rule's logic, written once, and it generates a new CRD kind, here `K8sAllowedRepos`.
- The **Constraint** is an instance of that kind. It holds the parameters, what to match, and how hard to enforce. It is the tuning knob.

So "allow only this registry" is a constraint edit, and "check something the rule cannot currently express" is a template edit. The exam nearly always asks for the first, and the reported tasks are consistently phrased as editing an existing policy rather than authoring one. Gatekeeper is never yours to install.

## Gotchas

- `nginx:1.27` is `docker.io/library/nginx:1.27`. A candidate who removes `docker.io/` and then tests with a bare image name and sees it refused has not found a bug; that is the rule working.
- `enforcementAction` has three values. `deny` refuses, `warn` admits with a warning, `dryrun` admits silently and only records a violation in `status`. Switching to `dryrun` while testing and forgetting to switch back is a way to pass your own check and fail the exam's.
- Gatekeeper reloads constraints asynchronously. Give it a couple of seconds after an edit before deciding it did not work.
- `kubectl get constraints` lists every constraint of every kind, which is the quickest way to see what a cluster is enforcing. There is no `kubectl get constraint <name>` without the kind.
- Gatekeeper ships an `--exempt-namespace` flag and its webhook usually skips `kube-system`. If a policy seems not to apply somewhere, check the namespace is not exempt before rewriting the rule.
- The rego field is `input.review.object`, and it only sees `spec.containers`. A rule written this way does not look at `initContainers` or `ephemeralContainers`, which is worth knowing when a question asks why an image got through.

## Docs

Gatekeeper's own documentation is **not** on the CKS allowed list. Only `kubernetes.io` and the other seven allowed domains are, and none of them documents `ConstraintTemplate`. So this is memorise territory:

- the two object kinds and which one holds the rego
- `spec.parameters`, `spec.match.kinds`, `spec.match.namespaces`, `spec.enforcementAction`
- `kubectl get constraints` and `kubectl get constrainttemplate`

What you can still reach in the exam is the cluster itself, and it will tell you the shape of these objects without any documentation at all:

```bash
kubectl explain k8sallowedrepos.spec.parameters
kubectl get k8sallowedrepos -o yaml
```

Q47 does the same job with `ValidatingAdmissionPolicy`, which is in-tree and whose documentation *is* allowed. When a question leaves the mechanism open, that is the one to reach for.
