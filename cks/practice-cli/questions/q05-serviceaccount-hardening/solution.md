# Q5. ServiceAccount Token Hardening (solution)

## Steps

Nothing here needs a node. The one thing to know before starting is that `serviceAccountName` is immutable on a running Pod, so this is a recreate rather than an edit.

**1. Confirm the token is mounted now.** Establish the starting state, so that its absence later means something.

```bash
kubectl -n app exec legacy -- ls /var/run/secrets/kubernetes.io/serviceaccount
```

```
ca.crt  namespace  token
```

**2. Create the ServiceAccount with automounting off.**

```bash
kubectl -n app create serviceaccount app-sa
kubectl -n app patch serviceaccount app-sa \
  -p '{"automountServiceAccountToken": false}'
```

Or in one step:

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: app-sa
  namespace: app
automountServiceAccountToken: false
EOF
```

Note the field sits at the **top level** of the ServiceAccount, not under a `spec:`. A ServiceAccount has no `spec`, and putting it there is a silent no-op that still applies cleanly.

**3. Recreate the Pod as that ServiceAccount, with the token off there too.**

```bash
cat <<'EOF' > /tmp/legacy.yaml
apiVersion: v1
kind: Pod
metadata:
  name: legacy
  namespace: app
spec:
  serviceAccountName: app-sa
  automountServiceAccountToken: false
  containers:
  - name: c
    image: busybox:1.36
    command: ["sleep", "3600"]
EOF
kubectl replace --force -f /tmp/legacy.yaml
```

`kubectl replace --force` deletes and recreates in one command, which is what an immutable field requires. `kubectl apply` would be rejected.

Setting it in both places is deliberate. The task asks for both, and the precedence is worth knowing: **the Pod's setting wins**. A Pod with `automountServiceAccountToken: true` gets a token even when its ServiceAccount says false, and a Pod that says false gets none even when the ServiceAccount says true. The ServiceAccount is the default; the Pod is the override.

**4. Wait for Running, then prove the mount is gone.**

```bash
kubectl -n app wait --for=condition=Ready pod/legacy --timeout=60s
kubectl -n app get pod legacy -o jsonpath='{.spec.serviceAccountName}{"\n"}'

kubectl -n app exec legacy -- ls /var/run/secrets/kubernetes.io/serviceaccount
```

```
ls: /var/run/secrets/kubernetes.io/serviceaccount: No such file or directory
```

That error is the pass. The directory is gone entirely, not merely empty. Checking the manifest instead would not distinguish a Pod that carries the field from one that is actually unmounted, which is the difference the question is about.

## Short-lived tokens when one is genuinely needed

Turning automounting off does not mean a workload can never call the API. It means it does not get a permanent ambient credential. When one is needed on purpose, mint it:

```bash
kubectl -n app create token app-sa --duration=10m
```

Or project one into the Pod with an explicit lifetime and audience, which is the pattern to reach for when a question says a token is needed but must be short-lived:

```yaml
  volumes:
  - name: sa-token
    projected:
      sources:
      - serviceAccountToken:
          path: token
          expirationSeconds: 3600
          audience: vault
```

## Why this matters

A mounted token is a credential sitting in the filesystem of every container in the Pod. Anything that reads a file, from a path-traversal bug to a debug sidecar to an attacker who has already got a shell, can read it and then talk to the API server as that ServiceAccount. Most workloads never call the API at all, so the token is pure attack surface. Removing it is the cheapest hardening step in the whole curriculum, which is why it is asked about.

## Gotchas

- `automountServiceAccountToken` is top-level on the ServiceAccount and under `spec` on the Pod. Two different placements of the same field name.
- The Pod's setting overrides the ServiceAccount's, in both directions.
- `serviceAccountName` is immutable. `kubectl replace --force -f` or delete and recreate.
- `serviceAccount` is the deprecated spelling of the same field and still appears in older manifests. Write `serviceAccountName`.
- Deleting the token Secret by hand does not help on any current cluster: tokens are projected by the kubelet, not read from a Secret, and a new one appears immediately.
- Check inside the container, not in the YAML. The verifier does, and so does the exam.

## Docs

`kubernetes.io/docs` is allowed and both pages below are quick to find.

- https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/
- https://kubernetes.io/docs/reference/access-authn-authz/service-accounts-admin/ for the projected-token fields
