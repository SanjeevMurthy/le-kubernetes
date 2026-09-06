# Q15. Static Analysis & Manifest Hardening (kubesec) (solution)

**Concept & Explanation:**

`kubesec` statically scores a workload manifest and lists specific advice: positive points for good settings, criticals for dangerous ones. You apply the recommended `securityContext` hardening to the file, reapply it, and re-scan to confirm the score rose. The scan reads a file, so the fix belongs in the manifest, not only in a `kubectl patch`.

**Solution — Step by Step:**

```bash
# 1. Read the advice
kubesec scan /opt/course/15/deploy.yaml

# 2. Harden the manifest
cat > /opt/course/15/deploy.yaml <<'YAML'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app
  namespace: appsec
spec:
  replicas: 1
  selector:
    matchLabels: {app: app}
  template:
    metadata:
      labels: {app: app}
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 10001
        seccompProfile: {type: RuntimeDefault}
      containers:
      - name: c
        image: nginx:1.27
        securityContext:
          runAsNonRoot: true
          readOnlyRootFilesystem: true
          allowPrivilegeEscalation: false
          capabilities: {drop: ["ALL"]}
        resources:
          limits: {cpu: "200m", memory: "128Mi"}
        volumeMounts: [{name: tmp, mountPath: /tmp}]
      volumes: [{name: tmp, emptyDir: {}}]
YAML

# 3. Reapply and re-scan
kubectl apply -f /opt/course/15/deploy.yaml
kubesec scan /opt/course/15/deploy.yaml    # score is now positive
```

**Key Points to Remember:**

- High-value fixes: no `privileged`, `readOnlyRootFilesystem: true`, `runAsNonRoot: true`, `capabilities.drop: [ALL]`, `allowPrivilegeEscalation: false`, `seccompProfile: RuntimeDefault`, plus resource limits.
- `readOnlyRootFilesystem: true` needs an `emptyDir` for every path the app writes; the stock `nginx` image also writes `/var/cache/nginx` and `/var/run`.
- Set `runAsNonRoot` on the pod, the container, or both; the container-level value wins.
- The task is graded on the **fixed manifest**, so edit the file and re-scan to prove it.

**Official Documentation:**
- https://kubesec.io/ · https://kubernetes.io/docs/tasks/configure-pod-container/security-context/

---
