# Q5. ServiceAccount Token Hardening (solution)

**Concept & Explanation:**

A mounted SA token is a stealable credential. Setting `automountServiceAccountToken: false` (on the SA or pod) removes `/var/run/secrets/kubernetes.io/serviceaccount/` from the container, shrinking the blast radius of a compromise.

**Solution — Step by Step:**

```bash
kubectl create serviceaccount app-sa -n app
kubectl patch serviceaccount app-sa -n app \
  -p '{"automountServiceAccountToken": false}'
```
```yaml
# Pod uses the SA and (belt-and-suspenders) disables automount at pod level:
apiVersion: v1
kind: Pod
metadata: {name: legacy, namespace: app}
spec:
  serviceAccountName: app-sa
  automountServiceAccountToken: false
  containers:
  - {name: c, image: nginx}
```
```bash
# Verify: the token dir should be absent
kubectl exec -n app legacy -- ls /var/run/secrets/kubernetes.io/serviceaccount 2>&1 # No such file
```

**Key Points to Remember:**

- Pod-level `automountServiceAccountToken` overrides the SA-level setting.
- Give workloads their **own** SA, never rely on `default`.
- Verify by exec-ing into the pod and confirming the token path is gone.

**Official Documentation:**
- https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/

---
