# Q4. RBAC Least-Privilege Role + Binding (solution)

## Steps

Nothing here needs a node. The work is one deletion, two creates, and a verification step that is worth more than the creates.

**1. Find the grant before removing it.** Never delete a binding by guessing its name. Find what actually binds this ServiceAccount, because a cluster can hold several.

```bash
kubectl get clusterrolebinding -o wide | grep -i ci
kubectl get clusterrolebinding ci-admin -o yaml
```

```yaml
roleRef:
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: ci
  namespace: build
```

**2. Remove it.** Delete the binding, not the ClusterRole. `cluster-admin` is a built-in that the rest of the cluster depends on, and deleting it is a far larger outage than the one you were asked to fix.

```bash
kubectl delete clusterrolebinding ci-admin
```

**3. Create the narrow Role.** Imperatively, because it is faster and cannot be mis-indented.

```bash
kubectl -n build create role ci-reader \
  --verb=get,list,watch \
  --resource=pods,pods/log
```

Check what that produced before binding it:

```bash
kubectl -n build get role ci-reader -o yaml
```

```yaml
rules:
- apiGroups: [""]
  resources: ["pods", "pods/log"]
  verbs: ["get", "list", "watch"]
```

**4. Bind it to the ServiceAccount.** The subject form is the part to have memorised, because there is no imperative shortcut that guesses it for you.

```bash
kubectl -n build create rolebinding ci-reader-binding \
  --role=ci-reader \
  --serviceaccount=build:ci
```

`--serviceaccount=<namespace>:<name>`. In YAML the same subject is:

```yaml
subjects:
- kind: ServiceAccount
  name: ci
  namespace: build
```

and the username RBAC actually evaluates is `system:serviceaccount:build:ci`, which is the form `--as` needs.

**5. Verify, including the negatives.** This is the step that distinguishes a correct answer from one that looks correct. A Role that grants too much passes every positive check.

```bash
# must be yes
kubectl auth can-i list pods   -n build --as system:serviceaccount:build:ci
kubectl auth can-i get pods/log -n build --as system:serviceaccount:build:ci

# must be no
kubectl auth can-i delete pods -n build      --as system:serviceaccount:build:ci
kubectl auth can-i get secrets -n build      --as system:serviceaccount:build:ci
kubectl auth can-i list pods   -n kube-system --as system:serviceaccount:build:ci
kubectl auth can-i '*' '*' --all-namespaces  --as system:serviceaccount:build:ci
```

The last one is the quickest way to confirm cluster-admin is really gone. It should answer `no`.

For the whole picture at once:

```bash
kubectl auth can-i --list -n build --as system:serviceaccount:build:ci
```

## Narrowing rather than replacing

When a question says to restrict an existing Role instead of creating one, edit it in place and keep its name and bindings intact:

```bash
kubectl -n build edit role <name>
```

Deleting and recreating a Role silently breaks every RoleBinding that referenced it by name, and RBAC does not warn you: the binding stays, points at nothing, and grants nothing. If you must recreate, recreate the bindings too.

## Role or ClusterRole

| | Role | ClusterRole |
|---|---|---|
| Scope of the rules | one namespace | cluster-wide |
| Binds with | RoleBinding | ClusterRoleBinding, or a RoleBinding |
| Cluster-scoped resources (nodes, PVs) | cannot grant | can grant |

The combination worth knowing is the third row of the middle column: a **RoleBinding that references a ClusterRole** grants that ClusterRole's rules inside one namespace only. It is how `view` and `edit` get handed out per namespace without writing a new Role each time.

## Gotchas

- `--serviceaccount=namespace:name` on the imperative command, but `system:serviceaccount:namespace:name` for `--as`. Two different spellings of the same subject, and mixing them up produces an answer that always says `no`.
- Subresources are separate strings. `pods/log` is not covered by `pods`.
- The core API group is `""`. `kubectl create role` fills it in; hand-written YAML has to say it.
- Wildcards in `verbs` or `resources` are almost never the right answer to a least-privilege question, and a `*` is the easiest thing for a grader to spot.
- Deleting the ClusterRoleBinding is the task. Deleting the `cluster-admin` ClusterRole itself breaks the cluster.
- `kubectl auth can-i` answers from the API server's live RBAC state, so it is proof rather than inference. Use it on the negatives, not just the positives.

## Docs

`kubernetes.io/docs` is allowed, and the RBAC page is one worth being able to reach in two clicks.

- https://kubernetes.io/docs/reference/access-authn-authz/rbac/
- `kubectl create role --help` and `kubectl create rolebinding --help`, which carry the flag spellings
