# Q4. RBAC Least-Privilege Role + Binding (solution)

**Concept & Explanation:**

Least privilege means granting the narrowest verbs/resources in the smallest scope. Here you remove the over-broad ClusterRoleBinding and add a namespaced Role + RoleBinding. `auth can-i --as` proves the result, which is how the task is graded.

**Solution — Step by Step:**

```bash
# 1. Remove the over-permissioned binding
kubectl delete clusterrolebinding ci-admin    # (whatever granted cluster-admin)

# 2. Create a tight Role + RoleBinding
kubectl create role ci-pod-reader \
  --verb=get,list,watch --resource=pods,pods/log -n build
kubectl create rolebinding ci-pod-reader \
  --role=ci-pod-reader --serviceaccount=build:ci -n build

# 3. VERIFY (graded on this)
kubectl auth can-i list pods   --as=system:serviceaccount:build:ci -n build   # yes
kubectl auth can-i delete pods --as=system:serviceaccount:build:ci -n build   # no
kubectl auth can-i get secrets --as=system:serviceaccount:build:ci -n build   # no
```

**Key Points to Remember:**

- Removing the broad binding is half the task — adding a tight one is the other half.
- `--as=system:serviceaccount:<ns>:<sa>` is the canonical verification.
- Use `Role`/`RoleBinding` (namespaced), not ClusterRole, to keep it scoped to `build`.

**Official Documentation:**
- https://kubernetes.io/docs/reference/access-authn-authz/rbac/
- https://kubernetes.io/docs/concepts/security/rbac-good-practices/

---
