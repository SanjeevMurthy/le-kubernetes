# Q7. AppArmor Profile on a Pod (solution)

**Concept & Explanation:**

AppArmor is a Linux MAC system that confines a process to an allow-list of capabilities/paths. The profile must be loaded into the kernel on the node **before** a pod references it. Kubernetes 1.30+ sets it via `securityContext.appArmorProfile`; older clusters use a `container.apparmor.security.beta.kubernetes.io/<container>` annotation.

**Solution — Step by Step:**

```bash
# On the node: load and confirm the profile
sudo apparmor_parser -q /etc/apparmor.d/k8s-deny-write
sudo aa-status | grep k8s-deny-write
```
```yaml
# Pod confined by the profile (Kubernetes 1.30+ field form)
apiVersion: v1
kind: Pod
metadata: {name: secure-pod}
spec:
  containers:
  - name: c
    image: busybox
    command: ["sh","-c","sleep 3600"]
    securityContext:
      appArmorProfile:
        type: Localhost
        localhostProfile: k8s-deny-write
```
```bash
# Verify enforcement: a write should be denied
kubectl exec secure-pod -- sh -c 'echo x > /root/test' 2>&1   # Permission denied
```

**Key Points to Remember:**

- The profile must be **loaded on the node first** (`apparmor_parser`); a pod referencing an unloaded profile won't start.
- 1.30+ uses `securityContext.appArmorProfile` (`type: Localhost`, `localhostProfile: <name>`); legacy uses the beta annotation.
- `aa-status` shows loaded profiles and enforce/complain mode.

**Official Documentation:**
- https://kubernetes.io/docs/tutorials/security/apparmor/
- https://kubernetes.io/docs/concepts/security/linux-kernel-security-constraints/

---
