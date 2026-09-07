# Q5. ServiceAccount Token Hardening (solution)

**Concept & Explanation:**

A mounted ServiceAccount token is a stealable credential. Setting `automountServiceAccountToken: false` on the ServiceAccount, or on the pod, removes `/var/run/secrets/kubernetes.io/serviceaccount/` from the container and shrinks the blast radius of a compromise. `serviceAccountName` is immutable, so an existing pod has to be recreated rather than patched.

**Solution — Step by Step:**

```bash
# 1. Dedicated ServiceAccount with automount disabled
kubectl create serviceaccount app-sa -n app
kubectl patch serviceaccount app-sa -n app -p '{"automountServiceAccountToken": false}'

# 2. Recreate the pod on that ServiceAccount
kubectl delete pod legacy -n app --now
kubectl apply -f - <<'YAML'
apiVersion: v1
kind: Pod
metadata: {name: legacy, namespace: app}
spec:
  serviceAccountName: app-sa
  automountServiceAccountToken: false
  containers:
  - name: legacy
    image: busybox:1.36
    command: ["sleep", "3600"]
YAML

# 3. Prove the token is gone
kubectl exec -n app legacy -- ls /var/run/secrets/kubernetes.io/serviceaccount   # No such file or directory
kubectl get pod legacy -n app -o jsonpath='{.spec.containers[*].volumeMounts[*].mountPath}{"\n"}'
```

**Key Points to Remember:**

- Pod-level `automountServiceAccountToken` overrides the ServiceAccount-level setting; either one alone removes the mount.
- Give every workload its **own** ServiceAccount; never leave it on `default`.
- `serviceAccountName` cannot be patched on a running pod — delete and recreate.
- Verify inside the container, not only in the spec: the token directory must be absent.

**Official Documentation:**
- https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/

---
