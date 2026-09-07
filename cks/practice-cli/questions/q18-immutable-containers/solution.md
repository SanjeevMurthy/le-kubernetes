# Q18. Immutable Containers (readOnlyRootFilesystem) (solution)

**Concept & Explanation:**

A read-only root filesystem stops an attacker writing payloads or modifying binaries inside a running container. Every path the process legitimately writes then has to be provided as a volume. The stock `nginx` image writes its pid file under `/var/run` and its temp files under `/var/cache/nginx`, so without those mounts the container crashes on start; that failure is the lesson, not a bug.

**Solution — Step by Step:**

```bash
kubectl patch deploy api -n immutable-lab --type='json' -p='[
  {"op":"add","path":"/spec/template/spec/containers/0/securityContext","value":{
     "readOnlyRootFilesystem": true,
     "allowPrivilegeEscalation": false}},
  {"op":"add","path":"/spec/template/spec/volumes","value":[
     {"name":"tmp","emptyDir":{}},
     {"name":"cache","emptyDir":{}},
     {"name":"run","emptyDir":{}}]},
  {"op":"add","path":"/spec/template/spec/containers/0/volumeMounts","value":[
     {"name":"tmp","mountPath":"/tmp"},
     {"name":"cache","mountPath":"/var/cache/nginx"},
     {"name":"run","mountPath":"/var/run"}]}
]'

kubectl rollout status deploy/api -n immutable-lab

# Prove the effect
kubectl exec -n immutable-lab deploy/api -- touch /tmp/probe    # succeeds
kubectl exec -n immutable-lab deploy/api -- touch /etc/probe    # Read-only file system
```

**Key Points to Remember:**

- `readOnlyRootFilesystem: true` plus an `emptyDir` for **every** writable path; miss one and the app CrashLoops.
- Pair it with `allowPrivilegeEscalation: false`, and add `runAsNonRoot: true` and `capabilities.drop: [ALL]` when the task asks for full hardening.
- The setting is per container, under `spec.template.spec.containers[].securityContext`, not on the pod.
- Verify by effect: a write outside the mounted paths must fail while the pod stays Running.

**Official Documentation:**
- https://kubernetes.io/docs/tasks/configure-pod-container/security-context/
