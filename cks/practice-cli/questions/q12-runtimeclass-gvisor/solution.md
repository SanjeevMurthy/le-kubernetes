# Q12. Runtime Sandbox with RuntimeClass (gVisor) (solution)

## Steps

containerd on the worker already knows about `runsc`. What is missing is the Kubernetes object that lets a Pod ask for it. That object is cluster-scoped, so it can be created from anywhere.

**1. Confirm the handler exists on the node.** If this is not there, no RuntimeClass will help and the Pod will fail to start with a runtime error rather than a scheduling one.

```bash
ssh <worker>
sudo -i
runsc --version
grep -A3 'runtimes.runsc' /etc/containerd/config.toml
```

```toml
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runsc]
  runtime_type = "io.containerd.runsc.v1"
```

The name after `runtimes.` is the handler name. That string is what the RuntimeClass must carry, and it is `runsc` in lowercase.

**2. Create the RuntimeClass.** It has no namespace and no `spec`; `handler` sits at the top level, which catches people out.

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: node.k8s.io/v1
kind: RuntimeClass
metadata:
  name: gvisor
handler: runsc
EOF

kubectl get runtimeclass
```

**3. Run the Pod, pinned to the node that has the runtime.** `runsc` is installed on one worker, and scheduling is not runtime-aware unless the RuntimeClass carries a `scheduling` block, so say where it goes.

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: sandboxed
  namespace: gvisor-lab
spec:
  runtimeClassName: gvisor
  nodeName: <worker>
  containers:
  - name: c
    image: busybox:1.36
    command: ["sleep", "3600"]
EOF

kubectl -n gvisor-lab wait --for=condition=Ready pod/sandboxed --timeout=90s
```

**4. Prove it is actually sandboxed.** This is the whole point of the question and the only check that cannot be faked by a correct-looking manifest.

```bash
kubectl -n gvisor-lab exec sandboxed -- dmesg | head -5
```

```
[    0.000000] Starting gVisor...
[    0.324018] Checking naughty and nice process list...
[    0.521274] Granting licence to kill(2)...
[    0.783891] Creating process schedule...
```

Those cheerful lines are gVisor's own fake kernel log, and seeing them is the pass. A normal container prints the host's real kernel ring buffer, full of hardware and driver messages, or fails with `Operation not permitted`. Either of those means the Pod ran on `runc` and the sandbox never happened.

Compare directly if you want to be certain:

```bash
kubectl -n gvisor-lab exec sandboxed -- uname -r      # a gVisor version string
```

## What gVisor actually does

A normal container shares the host kernel. Every syscall the container makes is served by the same kernel that serves the node, so a kernel vulnerability reachable from a syscall is reachable from inside any container on that host.

`runsc` puts a user-space kernel in between. The container's syscalls are handled by gVisor, which implements most of Linux itself and makes only a small, guarded set of real syscalls to the host. The container's escape surface shrinks from "the whole Linux syscall interface" to "what gVisor passes through".

The cost is compatibility and speed: not every syscall is implemented, and the ones that are cost more. That is why it is opt-in per Pod through a RuntimeClass rather than a cluster-wide setting, and why the curriculum files it under isolation techniques alongside PSA and network policy.

## Gotchas

- `handler: runsc` is top-level on the RuntimeClass. There is no `spec`, and adding one makes the object invalid.
- The handler name must match the containerd config exactly, lowercase included.
- RuntimeClass is cluster-scoped. `kubectl get runtimeclass -n something` silently ignores the namespace.
- The Pod must land on a node where the handler is configured. `nodeName` is the quick answer; the durable one is a `scheduling.nodeSelector` block on the RuntimeClass itself.
- A missing or misspelled `runtimeClassName` gives a Pod that runs perfectly well on `runc`. It looks like a pass everywhere except `dmesg`.
- If the Pod sits in `ContainerCreating`, read `kubectl describe pod`. `failed to get sandbox runtime: no runtime for "runsc" is configured` means the handler name is wrong or the Pod is on the wrong node.
- Q28 is the same setup with the `dmesg` output as a deliverable file, which is how killer.sh phrases it.

## Docs

`kubernetes.io/docs` is allowed. gVisor's own site is not, so `runsc --version` and the containerd config on the node are where the handler name comes from.

- https://kubernetes.io/docs/concepts/containers/runtime-class/
- `kubectl explain runtimeclass`, which confirms `handler` is top-level when you doubt it
