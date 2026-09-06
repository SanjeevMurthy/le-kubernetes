# Q18. Immutable Containers (readOnlyRootFilesystem) (solution)

**Concept & Explanation:**

A read-only root filesystem prevents an attacker from writing payloads or modifying binaries inside a running container. Any legitimately writable path is provided via an `emptyDir` mount so the app still works.

**Solution — Step by Step:**

```bash
kubectl patch deploy api -n prod --type='json' -p='[
  {"op":"add","path":"/spec/template/spec/containers/0/securityContext","value":{
     "readOnlyRootFilesystem": true,
     "allowPrivilegeEscalation": false,
     "runAsNonRoot": true}},
  {"op":"add","path":"/spec/template/spec/volumes","value":[{"name":"tmp","emptyDir":{}}]},
  {"op":"add","path":"/spec/template/spec/containers/0/volumeMounts","value":[{"name":"tmp","mountPath":"/tmp"}]}
]'
kubectl rollout status deploy/api -n prod
```

**Key Points to Remember:**

- `readOnlyRootFilesystem: true` + `emptyDir` for writable paths — without the emptyDir the app crashes if it writes.
- Pair with `allowPrivilegeEscalation: false` and `runAsNonRoot: true` for the full hardening.
- Verify: `kubectl exec ... -- touch /test` fails; `touch /tmp/test` succeeds.

**Official Documentation:**
- https://kubernetes.io/docs/tasks/configure-pod-container/security-context/
