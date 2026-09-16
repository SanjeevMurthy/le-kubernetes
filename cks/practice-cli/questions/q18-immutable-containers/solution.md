# Q18. Immutable Containers (readOnlyRootFilesystem) (solution)

## Steps

The hardening itself is two fields. The work is finding the paths nginx still needs to write to, because a read-only root filesystem without them gives you a Pod that crash-loops rather than one that is secure.

**1. See what the container writes today.** This is how you know which `emptyDir` mounts to add, and it generalises to any image the exam hands you.

```bash
kubectl -n immutable-lab exec deploy/api -- ls -ld /var/cache/nginx /var/run /tmp
kubectl -n immutable-lab exec deploy/api -- touch /etc/probe && echo "writable today"
```

**2. Patch the deployment.** The two security fields, plus a volume for each writable path.

```bash
cat <<'EOF' > /tmp/patch.yaml
spec:
  template:
    spec:
      containers:
      - name: api
        securityContext:
          readOnlyRootFilesystem: true
          allowPrivilegeEscalation: false
        volumeMounts:
        - name: tmp
          mountPath: /tmp
        - name: cache
          mountPath: /var/cache/nginx
        - name: run
          mountPath: /var/run
      volumes:
      - name: tmp
        emptyDir: {}
      - name: cache
        emptyDir: {}
      - name: run
        emptyDir: {}
EOF
kubectl -n immutable-lab patch deployment api --patch-file /tmp/patch.yaml
```

`kubectl edit deployment api -n immutable-lab` does the same thing and is often quicker under pressure. Either way the container name in the patch must match the existing one, or the patch adds a second container instead of modifying the first. That is the most common way this goes wrong and it is easy to miss, because the patch succeeds.

```bash
kubectl -n immutable-lab get deploy api \
  -o jsonpath='{.spec.template.spec.containers[*].name}{"\n"}'
```

**3. Wait for the rollout.**

```bash
kubectl -n immutable-lab rollout status deployment/api --timeout=120s
kubectl -n immutable-lab get pods
```

If the new Pods crash-loop, a writable path is still missing. The logs name it:

```bash
kubectl -n immutable-lab logs deploy/api | tail -20
```

```
nginx: [emerg] mkdir() "/var/cache/nginx/client_temp" failed (30: Read-only file system)
```

Add an `emptyDir` at the path in the error and roll again. That loop, read the error and mount what it names, is the whole technique.

**4. Prove both halves.** A read-only root that also blocks `/tmp` is not the answer; the task asked for writes to keep working where the application needs them.

```bash
# must succeed
kubectl -n immutable-lab exec deploy/api -- touch /tmp/probe && echo "/tmp writable: ok"

# must fail
kubectl -n immutable-lab exec deploy/api -- touch /etc/probe
```

```
touch: cannot touch '/etc/probe': Read-only file system
command terminated with exit code 1
```

That error is the pass.

## Why an emptyDir is not a hole in the hardening

Mounting a writable volume over `/tmp` looks like it undoes the point of a read-only root, and it does not. The value of `readOnlyRootFilesystem` is that an attacker cannot modify the **image**: no dropping a binary into `/usr/bin`, no editing `/etc/passwd` or a cron file, no persisting anything that survives a restart. An `emptyDir` is created fresh with the Pod and destroyed with it, so anything written there is gone the moment the container restarts. You have turned durable tampering into scratch space.

## Gotchas

- Match the existing container name. A patch with the wrong name silently adds a container rather than editing one.
- `readOnlyRootFilesystem` and `allowPrivilegeEscalation` are **container**-level. They have no Pod-level form, and putting them under the Pod's `securityContext` is accepted and ignored.
- nginx needs `/var/cache/nginx` and `/var/run` as well as `/tmp`. Other images need other paths; read the crash log rather than guessing.
- `emptyDir: {}` needs the braces. `emptyDir:` alone is null and the manifest is rejected.
- Deleting the Pod does not apply the change. Patch the Deployment; the ReplicaSet rolls it out.
- `kubectl exec deploy/api` picks one Pod from the Deployment. After a rollout, make sure you are talking to a new one and not a terminating old one.
- Q15 hardens the same class of workload from a manifest and a kubesec score; this one does it in the cluster and proves the effect.

## Docs

`kubernetes.io/docs` is allowed and covers both the field and the volume type.

- https://kubernetes.io/docs/tasks/configure-pod-container/security-context/
- https://kubernetes.io/docs/concepts/storage/volumes/#emptydir
