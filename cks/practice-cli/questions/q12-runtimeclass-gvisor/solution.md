# Q12. Runtime Sandbox with RuntimeClass (gVisor) (solution)

**Concept & Explanation:**

A RuntimeClass selects an alternate container runtime (handler) per pod. gVisor's `runsc` intercepts syscalls in userspace, isolating the container from the host kernel — strong isolation for untrusted workloads.

**Solution — Step by Step:**

```bash
kubectl apply -f - <<'EOF'
apiVersion: node.k8s.io/v1
kind: RuntimeClass
metadata: {name: gvisor}
handler: runsc
---
apiVersion: v1
kind: Pod
metadata: {name: sandboxed}
spec:
  runtimeClassName: gvisor
  containers:
  - {name: c, image: nginx}
EOF

# Verify the sandbox kernel differs from the host:
kubectl exec sandboxed -- dmesg 2>/dev/null | head    # gVisor signature
kubectl exec sandboxed -- uname -a
```

**Key Points to Remember:**

- `handler` must match the runtime name registered in `/etc/containerd/config.toml` (typically `runsc`).
- The pod sets `spec.runtimeClassName: gvisor`.
- If the handler isn't installed, the pod stays `Pending`/`ContainerCreating` — confirm node setup.

**Official Documentation:**
- https://kubernetes.io/docs/concepts/containers/runtime-class/
---
