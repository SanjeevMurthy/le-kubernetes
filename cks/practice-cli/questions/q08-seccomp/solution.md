# Q8. Seccomp RuntimeDefault + Custom Profile (solution)

**Concept & Explanation:**

Seccomp filters the syscalls a container may make. `RuntimeDefault` applies the container runtime's curated profile (recommended baseline). Custom profiles are JSON files placed under `/var/lib/kubelet/seccomp/` and referenced by relative path via `type: Localhost`.

**Solution — Step by Step:**

```yaml
# Custom profile at /var/lib/kubelet/seccomp/profiles/audit.json
apiVersion: v1
kind: Pod
metadata: {name: audited, namespace: seccomp-lab}
spec:
  securityContext:
    seccompProfile:
      type: Localhost
      localhostProfile: profiles/audit.json
  containers:
  - {name: c, image: busybox:1.36, command: ["sh","-c","sleep 3600"]}
---
# RuntimeDefault (pod-level securityContext)
apiVersion: v1
kind: Pod
metadata: {name: default-seccomp, namespace: seccomp-lab}
spec:
  securityContext:
    seccompProfile: {type: RuntimeDefault}
  containers:
  - {name: c, image: busybox:1.36, command: ["sh","-c","sleep 3600"]}
```
```bash
# The custom profile file already exists on the worker:
#   /var/lib/kubelet/seccomp/profiles/audit.json  -> {"defaultAction":"SCMP_ACT_LOG"}

# Verify the applied profile:
kubectl get pod audited -n seccomp-lab -o jsonpath='{.spec.securityContext.seccompProfile}'

# Effect check on the worker — mode 2 means a seccomp filter is loaded:
CID=$(sudo crictl ps -q --name audited)
PID=$(sudo crictl inspect --output go-template --template '{{.info.pid}}' "$CID")
sudo grep Seccomp: /proc/$PID/status        # Seccomp:  2
```

**Key Points to Remember:**

- `localhostProfile` is **relative to `/var/lib/kubelet/seccomp/`** — don't use an absolute path.
- The JSON file must exist on the node where the pod is scheduled, or the pod fails to start.
- `RuntimeDefault` is the easy, recommended baseline and satisfies the `restricted` PSS.

**Official Documentation:**
- https://kubernetes.io/docs/tutorials/security/seccomp/

---
