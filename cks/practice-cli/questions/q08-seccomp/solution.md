# Q8. Seccomp RuntimeDefault + Custom Profile (solution)

**Concept & Explanation:**

Seccomp filters the syscalls a container may make. `RuntimeDefault` applies the container runtime's curated profile (recommended baseline). Custom profiles are JSON files placed under `/var/lib/kubelet/seccomp/` and referenced by relative path via `type: Localhost`.

**Solution — Step by Step:**

```yaml
# RuntimeDefault (pod-level securityContext)
apiVersion: v1
kind: Pod
metadata: {name: audited}
spec:
  securityContext:
    seccompProfile: {type: RuntimeDefault}
  containers: [{name: c, image: nginx}]
---
# Custom profile at /var/lib/kubelet/seccomp/profiles/audit.json
apiVersion: v1
kind: Pod
metadata: {name: custom}
spec:
  securityContext:
    seccompProfile:
      type: Localhost
      localhostProfile: profiles/audit.json
  containers: [{name: c, image: nginx}]
```
```bash
# The custom profile file (on the node), e.g. an audit-logging profile:
sudo mkdir -p /var/lib/kubelet/seccomp/profiles
# (place audit.json with {"defaultAction":"SCMP_ACT_LOG"} or similar)

# Verify the applied profile:
kubectl get pod custom -o jsonpath='{.spec.securityContext.seccompProfile}'
sudo crictl inspect <container-id> | grep -i seccomp
```

**Key Points to Remember:**

- `localhostProfile` is **relative to `/var/lib/kubelet/seccomp/`** — don't use an absolute path.
- The JSON file must exist on the node where the pod is scheduled, or the pod fails to start.
- `RuntimeDefault` is the easy, recommended baseline and satisfies the `restricted` PSS.

**Official Documentation:**
- https://kubernetes.io/docs/tutorials/security/seccomp/

---
