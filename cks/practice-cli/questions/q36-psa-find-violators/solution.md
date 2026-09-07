# Q36. Pod Security: enforce baseline and report violators (solution)

<!-- toc -->
## Table of Contents

- [Steps](#steps)
- [Why](#why)
- [Verify](#verify)
- [Docs](#docs)

<!-- toc stop -->

## Steps

**1. Look at what is running.**

```bash
kubectl get pods -n psa-lab
```

Three pods: `clean`, `hostpid`, `priv`.

**2. Ask the API server which of them violate baseline, before changing anything.**

A server-side dry run of the label puts the request through the PodSecurity admission plugin, which evaluates every existing pod and reports the ones that would not be admitted. Nothing is written.

```bash
kubectl label --dry-run=server --overwrite ns psa-lab \
  pod-security.kubernetes.io/enforce=baseline
```

```
Warning: existing pods in namespace "psa-lab" violate the new PodSecurity enforce level "baseline:latest"
Warning: hostpid: host namespaces
Warning: priv: privileged
namespace/psa-lab labeled (server dry run)
```

Each warning after the first is `<pod name>: <what it violated>`.

**3. Write the deliverable.** The warnings arrive on stderr, so redirect it.

```bash
mkdir -p /opt/course/36
kubectl label --dry-run=server --overwrite ns psa-lab \
  pod-security.kubernetes.io/enforce=baseline 2>&1 \
  | grep '^Warning:' | grep -v 'violate the new' \
  | sed 's/^Warning: //' | cut -d: -f1 | sort > /opt/course/36/violators.txt

cat /opt/course/36/violators.txt
```

```
hostpid
priv
```

Typing the two names by hand is just as good and takes less time than getting the pipeline right under pressure. What matters is that `clean` is not in the file.

**4. Now apply the label for real.**

```bash
kubectl label --overwrite ns psa-lab pod-security.kubernetes.io/enforce=baseline
kubectl get ns psa-lab --show-labels
```

**5. Confirm the pods were not evicted and that new ones are filtered.**

```bash
kubectl get pods -n psa-lab
kubectl run probe -n psa-lab --image=busybox:1.36 --restart=Never --dry-run=server -- sleep 1
kubectl run bad -n psa-lab --image=busybox:1.36 --restart=Never --dry-run=server \
  --overrides='{"spec":{"containers":[{"name":"bad","image":"busybox:1.36","securityContext":{"privileged":true}}]}}' -- sleep 1
```

The first is accepted, the second is `forbidden`.

**6. Cross-check by reading the specs**, which is the fallback when the warnings do not appear.

```bash
kubectl get pods -n psa-lab -o jsonpath='{range .items[*]}{.metadata.name}{"  hostPID="}{.spec.hostPID}{"  privileged="}{.spec.containers[*].securityContext.privileged}{"\n"}{end}'
```

`priv` runs a privileged container and `hostpid` shares the host PID namespace. Both are forbidden by baseline. `clean` sets nothing, and baseline still allows running as root, so it passes.

## Why

Pod Security Admission has three modes on a namespace, and the exam trades on the difference between them. `enforce` rejects a pod at admission time. `audit` records a violation in the audit log. `warn` returns a warning to the client. Each takes a level, `privileged`, `baseline` or `restricted`, and optionally a `-version` label to pin the level to a Kubernetes release.

`enforce` is applied only when a pod is created or updated. It never touches a pod that is already running, and there is no controller that goes back and evicts one. Labelling a busy namespace therefore leaves exactly the situation in this question: the standard is enforced, and the workloads that violate it are still there, unnoticed. That gap is the reason the second half of the task exists. Finding those pods is the real work, and it is what an auditor asks for.

The dry-run trick works because the warning is produced by the admission plugin as it evaluates the **namespace update**, not by `kubectl`. The plugin scans the pods in the namespace and reports the ones the new level would reject. It only reports when the level actually changes, so run it while the namespace is still unlabelled. If the label has already been applied, get the same output from a level that is not yet set:

```bash
kubectl label --dry-run=server --overwrite ns psa-lab pod-security.kubernetes.io/warn=baseline
```

Baseline blocks the things that break the boundary between the container and the node: privileged containers, host namespaces (`hostPID`, `hostIPC`, `hostNetwork`), host ports, host path volumes, added capabilities beyond a small list, and unconfined AppArmor or seccomp. It deliberately does not require a non-root user, a read-only root filesystem or a seccomp profile. Those belong to `restricted`, which is why a plain busybox pod passes baseline and fails restricted.

## Verify

```bash
kubectl get ns psa-lab -o jsonpath='{.metadata.labels.pod-security\.kubernetes\.io/enforce}{"\n"}'
cat /opt/course/36/violators.txt
kubectl get pods -n psa-lab
```

## Docs

**Allowed:** `https://kubernetes.io/docs/concepts/security/pod-security-standards/` for what each level forbids, and `https://kubernetes.io/docs/tasks/configure-pod-security-admission/` for the label syntax and the dry-run example.

Memorise the label prefix, `pod-security.kubernetes.io/`, and the three modes. Searching for it costs more time than the whole task is worth.
