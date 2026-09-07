# Q30. seccomp: block mkdir with a Localhost profile (solution)

## Steps

**1. Write the profile on the worker node.** `localhostProfile` is resolved by the kubelet on the node that runs the Pod, so the file has to exist there, not on the control plane.

```bash
ssh <worker>
sudo -i
mkdir -p /var/lib/kubelet/seccomp/profiles

cat > /var/lib/kubelet/seccomp/profiles/no-mkdir.json <<'EOF'
{
  "defaultAction": "SCMP_ACT_ALLOW",
  "syscalls": [
    {
      "names": ["mkdir", "mkdirat"],
      "action": "SCMP_ACT_ERRNO"
    }
  ]
}
EOF

chmod 0644 /var/lib/kubelet/seccomp/profiles/no-mkdir.json
exit
```

Both names are needed. A libc `mkdir()` call goes to the `mkdirat` syscall on current systems, and on arm64 the `mkdir` syscall does not exist at all. Listing only `mkdir` produces a profile that loads cleanly and blocks nothing.

**2. Create the Pod.** `seccompProfile` sits under `securityContext`, and the path is relative to `/var/lib/kubelet/seccomp`, so it is `profiles/no-mkdir.json` and not the absolute path.

```bash
W=$(kubectl get nodes -l '!node-role.kubernetes.io/control-plane' -o name | head -1 | cut -d/ -f2)

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: sandboxed
  namespace: seccomp-lab
spec:
  nodeName: $W
  securityContext:
    seccompProfile:
      type: Localhost
      localhostProfile: profiles/no-mkdir.json
  containers:
    - name: c
      image: busybox:1.36
      command: ["sleep", "3600"]
EOF

kubectl -n seccomp-lab get pod sandboxed -w
```

If the Pod sticks in `CreateContainerError`, read the event. `cannot load seccomp profile` means the path is wrong or the file is not on that node.

**3. Show that ordinary work still succeeds.** This is worth doing before the denial, because a Pod that cannot do anything is not a passing answer.

```bash
kubectl exec -n seccomp-lab sandboxed -- touch /tmp/ok && echo "writes still work"
```

**4. Trigger the denial and keep the error.** The message goes to stderr, so redirect it.

```bash
mkdir -p /opt/course/30
kubectl exec -n seccomp-lab sandboxed -- mkdir /tmp/blocked > /opt/course/30/result.txt 2>&1
cat /opt/course/30/result.txt
```

```
mkdir: can't create directory '/tmp/blocked': Operation not permitted
```

## Why

A seccomp profile is a default plus a list of exceptions, and which way round they go changes everything. `SCMP_ACT_ALLOW` as the default with a short deny list is a blocklist: easy to write, easy to keep a workload running, and easy to bypass because anything not named is permitted. `SCMP_ACT_ERRNO` as the default with an allow list is what `RuntimeDefault` and the Docker profile actually do, and it is far stronger, but it takes a full syscall trace of the workload to build. The task asks for the first shape because it isolates one syscall.

The action decides what the process sees. `SCMP_ACT_ERRNO` returns `EPERM` from the call, so the program gets an ordinary error it can handle and keeps running, which is why the container stays up and `mkdir` merely fails. `SCMP_ACT_KILL` would terminate the process instead, and the Pod would restart-loop rather than produce the error message this task asks you to capture. `SCMP_ACT_LOG` allows the call and records it, which is how you build an allow list without breaking anything.

The filter is installed by the container runtime at container start and is inherited by every child process. It cannot be relaxed afterwards, which is why a change to the profile requires the Pod to be recreated, not restarted.

The relative path trips people up. `/var/lib/kubelet/seccomp` is the kubelet's seccomp root (its `--root-dir` plus `seccomp`), and `localhostProfile` is always relative to it. An absolute path is rejected by the API server.

## Verify

```bash
cat /var/lib/kubelet/seccomp/profiles/no-mkdir.json          # on the worker
kubectl -n seccomp-lab get pod sandboxed -o wide             # Running, on the worker
kubectl -n seccomp-lab get pod sandboxed \
  -o jsonpath='{.spec.securityContext.seccompProfile}'; echo
kubectl exec -n seccomp-lab sandboxed -- touch /tmp/ok       # succeeds
kubectl exec -n seccomp-lab sandboxed -- mkdir /tmp/blocked  # Operation not permitted
cat /opt/course/30/result.txt
```

## Docs

**Allowed:** `https://kubernetes.io/docs/tutorials/security/seccomp/` has a copyable profile and the `securityContext.seccompProfile` block, and `https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/#security-context` has the field reference.

Worth memorising: the seccomp root is `/var/lib/kubelet/seccomp`, `localhostProfile` is relative to it, `type` is one of `RuntimeDefault`, `Localhost` or `Unconfined`, and the actions are `SCMP_ACT_ALLOW`, `SCMP_ACT_ERRNO`, `SCMP_ACT_LOG` and `SCMP_ACT_KILL`.
