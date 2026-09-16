# Q8. Seccomp RuntimeDefault + Custom Profile (solution)

## Steps

The profile lives on the worker's filesystem, and the proof lives in `/proc` on that same worker, so get a root shell there before anything else.

```bash
ssh <worker>            # the name the setup printed
sudo -i
hostname
```

**1. Confirm the seccomp root and the profile.** `localhostProfile` is interpreted relative to the kubelet's seccomp root, so knowing the root is what makes the path in the manifest correct.

```bash
ls -l /var/lib/kubelet/seccomp/profiles/audit.json
cat /var/lib/kubelet/seccomp/profiles/audit.json
```

```json
{
  "defaultAction": "SCMP_ACT_LOG"
}
```

The root here is `/var/lib/kubelet/seccomp`, so the profile's path in the Pod is `profiles/audit.json`. Not the absolute path, and no leading slash. An absolute path leaves the Pod stuck in `CreateContainerError`.

**2. Create both pods, pinned to this worker.** The profile only exists on this node, so a Pod scheduled elsewhere fails to start.

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: audited
  namespace: seccomp-lab
spec:
  nodeName: <worker>
  securityContext:
    seccompProfile:
      type: Localhost
      localhostProfile: profiles/audit.json
  containers:
  - name: c
    image: busybox:1.36
    command: ["sleep", "3600"]
---
apiVersion: v1
kind: Pod
metadata:
  name: default-seccomp
  namespace: seccomp-lab
spec:
  nodeName: <worker>
  securityContext:
    seccompProfile:
      type: RuntimeDefault
  containers:
  - name: c
    image: busybox:1.36
    command: ["sleep", "3600"]
EOF
```

`localhostProfile` is only valid when `type` is `Localhost`, and is rejected outright with `RuntimeDefault`.

**3. Wait for both, then prove the confinement is real.** A Pod carrying the field and a Pod actually filtered look identical in `kubectl get`.

```bash
kubectl -n seccomp-lab wait --for=condition=Ready pod/audited pod/default-seccomp --timeout=60s
```

Find the container, then its host pid, then read what the kernel says about it:

```bash
CID=$(crictl ps --name c --label io.kubernetes.pod.name=audited -q)
PID=$(crictl inspect --output go-template --template '{{.info.pid}}' "$CID")
grep Seccomp /proc/"$PID"/status
```

```
Seccomp:	2
Seccomp_filters:	1
```

`2` is filter mode, which is the pass. `0` means no filter is loaded at all, and it is what you get when the Pod carries the field but the profile never applied.

## The three types

| `type` | What it loads | When to use it |
|---|---|---|
| `RuntimeDefault` | the container runtime's own profile, which blocks around 40 dangerous syscalls | the default answer to "harden this Pod" |
| `Localhost` | a JSON profile from the kubelet's seccomp root | when the question hands you a profile or asks to block a named syscall |
| `Unconfined` | nothing | never, in an exam answer |

`RuntimeDefault` is the one to reach for unless the question gives you a file. It requires nothing on disk and is the field `restricted` Pod Security Standard demands.

## The actions inside a profile

Worth recognising, because a question may hand you a profile and ask what it does:

- `SCMP_ACT_LOG` — allow the syscall and write it to the audit log. This is what `audit.json` does: it confines nothing and observes everything, which is how you find out what a workload actually needs.
- `SCMP_ACT_ERRNO` — refuse the syscall with an error. This is the one that blocks. Q30 uses it to deny `mkdir`.
- `SCMP_ACT_ALLOW` — permit. Used as the default with a deny list, or per-syscall with a deny default.

A profile with `"defaultAction": "SCMP_ACT_ERRNO"` and no `syscalls` list blocks everything and the container cannot start at all, which is a good thing to have seen once before an exam.

## Gotchas

- `localhostProfile` is relative to `/var/lib/kubelet/seccomp`. An absolute path is the most common error and shows up as `CreateContainerError`, not as a Pod that runs unconfined.
- The seccomp root can be moved with the kubelet's `--seccomp-profile-root`. Check `/var/lib/kubelet/config.yaml` if the default path is empty.
- The profile file must exist on the node where the Pod is scheduled. Pin with `nodeName` or place it on every node.
- `seccompProfile` at Pod level applies to every container; at container level it overrides for that one.
- The old `seccomp.security.alpha.kubernetes.io/pod` annotation was removed in 1.25. Do not write it.
- Verify with `/proc/<pid>/status`, not with `kubectl get -o yaml`. The manifest tells you what was asked for; `/proc` tells you what happened.
- `crictl` needs root. If it reports a connection error, you are not in a `sudo -i` shell.

## Docs

`kubernetes.io/docs` is allowed and its seccomp tutorial contains the exact field block, which is quicker to copy than to type under pressure.

- https://kubernetes.io/docs/tutorials/security/seccomp/
- https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/#security-context for `seccompProfile`
- `man 2 seccomp` on the node for the mode values in `/proc/<pid>/status`
