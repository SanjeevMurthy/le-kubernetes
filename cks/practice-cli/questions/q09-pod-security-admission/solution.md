# Q9. Enforce Pod Security Admission (restricted) (solution)

## Steps

Pod Security Admission is built into the API server and is driven entirely by labels on the namespace. There is nothing to install and nothing to create.

**1. Label the namespace.** One command sets both modes the task asks for.

```bash
kubectl label namespace payments \
  pod-security.kubernetes.io/enforce=restricted \
  pod-security.kubernetes.io/warn=restricted \
  --overwrite
```

`--overwrite` matters: without it the command fails if the namespace already carries a different value, which is the usual state in a question that says "change the policy".

Pin the version too when a question asks for it, so a cluster upgrade cannot silently change what `restricted` means:

```bash
kubectl label namespace payments \
  pod-security.kubernetes.io/enforce-version=v1.34 --overwrite
```

**2. Read the labels back.**

```bash
kubectl get namespace payments -o jsonpath='{.metadata.labels}' | tr ',' '\n'
```

**3. Prove a bad Pod is rejected.** `--dry-run=server` runs the request through admission and discards it, so you get the real answer without creating anything or waiting for an image pull.

```bash
kubectl -n payments run bad --image=nginx:1.27 --dry-run=server \
  --overrides='{"spec":{"containers":[{"name":"bad","image":"nginx:1.27","securityContext":{"privileged":true}}]}}'
```

```
Error from server (Forbidden): pods "bad" is forbidden: violates PodSecurity
"restricted:latest": privileged (container "bad" must not set securityContext.privileged=true), ...
```

**4. Prove a compliant Pod is admitted.** This half matters as much: a namespace that rejects everything, valid Pods included, is not a pass.

```bash
cat <<'EOF' | kubectl apply --dry-run=server -f -
apiVersion: v1
kind: Pod
metadata:
  name: good
  namespace: payments
spec:
  securityContext:
    runAsNonRoot: true
    seccompProfile:
      type: RuntimeDefault
  containers:
  - name: c
    image: busybox:1.36
    command: ["sleep", "3600"]
    securityContext:
      allowPrivilegeEscalation: false
      capabilities:
        drop: ["ALL"]
EOF
```

## The four fields `restricted` demands

This is the list to be able to write from memory, because a question that asks you to *fix* a Pod rather than label a namespace is asking for exactly these:

```yaml
spec:
  securityContext:
    runAsNonRoot: true              # 1
    seccompProfile:
      type: RuntimeDefault          # 2
  containers:
  - name: c
    securityContext:
      allowPrivilegeEscalation: false   # 3
      capabilities:
        drop: ["ALL"]                   # 4
```

Two of them are Pod-level and two are container-level, and putting one in the wrong place is the usual reason a Pod that "has all four" is still rejected.

## The three modes and the three levels

Modes, which can be set independently and all at once:

- `enforce` — reject the Pod.
- `audit` — admit it, record a violation in the audit log.
- `warn` — admit it, return a warning to the user's terminal.

Levels:

- `privileged` — unrestricted.
- `baseline` — blocks the well-known escapes: privileged, hostNetwork, hostPID, hostPath, added capabilities beyond a small set.
- `restricted` — baseline plus the four fields above.

Setting `warn` alongside `enforce`, as this task asks, is the practical combination: `enforce` stops the Pod and `warn` makes the reason visible to whoever applied it.

## Gotchas

- `enforce` applies to Pods being **created or updated**. It never evicts anything. A namespace full of privileged Pods stays exactly as it is after you label it, and that is not a mistake in your answer. Q36 is the question about finding those existing violators.
- Deployments are not Pods. A Deployment whose template violates the policy is accepted; its ReplicaSet then fails to create Pods, and the error appears in `kubectl describe replicaset`, not on the `kubectl apply`. The `warn` mode is what surfaces it at apply time.
- The label prefix is `pod-security.kubernetes.io/`, and the value is the level. Reversing them produces a label the API server ignores in silence.
- `--dry-run=server` reaches admission; `--dry-run=client` does not and always appears to succeed.
- PSA cannot be scoped to individual Pods, only namespaces. When a question needs finer control than three levels, it wants an admission policy instead, which is Q47's ValidatingAdmissionPolicy or Q11's Kyverno.
- `kube-system` is exempt by default in most distributions. Do not conclude the labels failed because a kube-system Pod still runs.

## Docs

`kubernetes.io/docs` is allowed and the standards page lists every field each level checks, which is the page to find rather than memorise in full.

- https://kubernetes.io/docs/concepts/security/pod-security-admission/
- https://kubernetes.io/docs/concepts/security/pod-security-standards/
