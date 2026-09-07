# Q9. Enforce Pod Security Admission (restricted) (solution)

**Concept & Explanation:**

Pod Security Admission enforces the Pod Security Standards via namespace labels — no extra objects. `restricted` blocks privilege escalation, host namespaces, running as root, and requires a seccomp profile.

**Solution — Step by Step:**

```bash
kubectl label ns payments \
  pod-security.kubernetes.io/enforce=restricted \
  pod-security.kubernetes.io/warn=restricted

# Should be REJECTED:
kubectl run bad --image=nginx -n payments \
  --overrides='{"spec":{"containers":[{"name":"bad","image":"nginx","securityContext":{"privileged":true}}]}}'

# Should be ADMITTED:
kubectl apply -n payments -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata: {name: good}
spec:
  securityContext: {runAsNonRoot: true, seccompProfile: {type: RuntimeDefault}}
  containers:
  - name: c
    image: nginx
    securityContext:
      allowPrivilegeEscalation: false
      capabilities: {drop: ["ALL"]}
EOF
```

**Key Points to Remember:**

- The entire task is namespace **labels** — `enforce`/`warn`/`audit` with a level.
- `restricted` requires `runAsNonRoot`, `allowPrivilegeEscalation: false`, `capabilities.drop:[ALL]`, `seccompProfile`.
- Prove it: the privileged pod must be **forbidden**; the compliant one must run.

**Official Documentation:**
- https://kubernetes.io/docs/concepts/security/pod-security-admission/
- https://kubernetes.io/docs/concepts/security/pod-security-standards/

---
