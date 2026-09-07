# Q12. Runtime Sandbox with RuntimeClass (gVisor)

**Host:** any node with `kubectl`; the sandboxed pod must land on the worker node named in
the setup output, which is where gVisor (`runsc`) is installed.

The worker node has the gVisor `runsc` runtime handler configured in containerd, but the
cluster has no `RuntimeClass` for it, so nothing can use it yet. Namespace `gvisor-lab`
is empty.

1. Create a cluster-scoped `RuntimeClass` named `gvisor` with `handler: runsc`.
2. Run a pod named `sandboxed` in namespace `gvisor-lab`, image `busybox:1.36`, command
   `sleep 3600`, that uses `spec.runtimeClassName: gvisor`.
3. Confirm the pod is `Running` and that it really is sandboxed: `kubectl exec -n gvisor-lab
   sandboxed -- dmesg` must report the gVisor kernel, not the host kernel.
