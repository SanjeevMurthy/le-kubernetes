# Q15. Static Analysis & Manifest Hardening (kubesec) (solution)

**Concept & Explanation:**

`kubesec` statically scores a workload manifest and lists specific advice (positive points for good settings, criticals for bad ones). You apply the recommended `securityContext` hardening and re-scan to confirm the score rose.

**Solution — Step by Step:**

```bash
kubesec scan app.yaml         # read the "advise" + "critical" lists
```
```yaml
# Hardened pod
apiVersion: v1
kind: Pod
metadata: {name: app}
spec:
  securityContext: {runAsNonRoot: true, runAsUser: 1000}
  containers:
  - name: c
    image: nginx
    securityContext:
      readOnlyRootFilesystem: true
      allowPrivilegeEscalation: false
      capabilities: {drop: ["ALL"]}
    resources:
      limits: {cpu: "200m", memory: "128Mi"}
    volumeMounts: [{name: tmp, mountPath: /tmp}]
  volumes: [{name: tmp, emptyDir: {}}]
```
```bash
kubesec scan app.yaml         # score should be higher / criticals cleared
```

**Key Points to Remember:**

- High-value fixes: drop `privileged`, set `readOnlyRootFilesystem`, `runAsNonRoot`, `capabilities.drop:[ALL]`, `allowPrivilegeEscalation:false`, add resource limits.
- `readOnlyRootFilesystem: true` needs an `emptyDir` for any path the app writes (e.g. `/tmp`).
- The task is graded on the **fixed manifest** — re-scan to prove it.

**Official Documentation:**
- https://kubesec.io/ · https://kubernetes.io/docs/tasks/configure-pod-container/security-context/

---
