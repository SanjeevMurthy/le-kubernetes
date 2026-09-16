# Q7. AppArmor Profile on a Pod (solution)

## Steps

AppArmor is a kernel feature on the node. The profile is loaded on the node, by you, as root. Nothing about step 1 involves the cluster.

```bash
ssh <worker>            # the name the setup printed
sudo -i
hostname
```

**1. See what is loaded now.** The profile file exists but the kernel has never been told about it, so it will not be in this list.

```bash
aa-status | head -20
apparmor_status | grep k8s-deny-write      # nothing yet
```

**2. Read the profile's own name.** This is the trap in this whole family of questions, and it is worth doing every time rather than assuming.

```bash
head -5 /etc/apparmor.d/k8s-deny-write
```

```
#include <tunables/global>

profile k8s-deny-write flags=(attach_disconnected) {
```

The name Kubernetes needs is the word after `profile`, not the file name. Here they happen to match. In Q34 they deliberately do not, and a pod that names the file instead of the profile stays `Pending` forever with `cannot find AppArmor profile`.

**3. Load it in enforce mode.**

```bash
apparmor_parser -q /etc/apparmor.d/k8s-deny-write
```

`-q` is quiet, `-r` replaces an already-loaded profile, and `-a` adds a new one. `apparmor_parser -r` is the one to reach for when you have edited a profile that is already loaded, because plain loading of an existing profile is an error.

**4. Confirm the kernel has it, in the right mode.** Loaded in `complain` mode looks almost identical and enforces nothing.

```bash
aa-status | grep -A20 'profiles are in enforce mode' | grep k8s-deny-write
```

**5. Create the pod, pinned to this node.** The profile is loaded on one node only, so the pod must land there. Kubernetes will not tell you the profile is missing until the kubelet on the chosen node tries to start the container.

```bash
cat > /tmp/secure-pod.yaml <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: secure-pod
  namespace: apparmor-lab
spec:
  nodeName: <worker>
  securityContext:
    appArmorProfile:
      type: Localhost
      localhostProfile: k8s-deny-write
  containers:
  - name: c
    image: busybox:1.36
    command: ["sleep", "3600"]
EOF
kubectl apply -f /tmp/secure-pod.yaml
kubectl -n apparmor-lab get pod secure-pod -o wide
```

`securityContext.appArmorProfile` is the field as of Kubernetes 1.30 and is what to write today. It exists at pod level, as above, and at container level under `spec.containers[].securityContext`.

**6. Prove the confinement, which is the only thing that counts.** A pod that carries the field but runs unconfined passes every YAML inspection and fails the task.

```bash
kubectl -n apparmor-lab exec secure-pod -- touch /tmp/apparmor-probe
```

```
touch: /tmp/apparmor-probe: Permission denied
command terminated with exit code 1
```

A `Permission denied` here is the pass. Read it from the node's side too, because that is where the reason is recorded:

```bash
dmesg | grep -i apparmor | tail -5
journalctl -k | grep 'apparmor="DENIED"' | tail -5
```

## The legacy annotation

Before 1.30 the profile was attached with an annotation, and it is still accepted:

```yaml
metadata:
  annotations:
    container.apparmor.security.beta.kubernetes.io/<container-name>: localhost/k8s-deny-write
```

Two things about it are worth carrying into the exam. The key ends with the **container** name, not the pod's, and the value is prefixed `localhost/`. If a question hands you a manifest that already uses the annotation, the smaller edit is usually to fix the annotation rather than convert it.

## Gotchas

- The profile name inside the file is what `localhostProfile` takes. Never the file name, never a path, and no `localhost/` prefix on the modern field.
- The pod must be scheduled where the profile is loaded. Use `nodeName`, or load the profile on every node.
- A missing profile leaves the pod `Pending` or in `CreateContainerError`, not `Running` with no confinement. `kubectl describe pod` names it directly.
- `complain` mode logs and permits. Only `enforce` denies. `aa-complain` and `aa-enforce` switch between them.
- Editing a loaded profile needs `apparmor_parser -r` to replace it; loading it again without `-r` fails.
- Pods cannot be edited into a different profile. `kubectl replace --force -f` is the way to re-create one.
- AppArmor's documentation is **not** on the exam's allowed list. `apparmor_parser`, `aa-status`, the field path and the annotation form all have to come from memory, or from `man apparmor_parser` on the node.

## Docs

No allowed web documentation covers AppArmor itself. `kubernetes.io/docs` does cover the Kubernetes side, and the node has man pages.

- https://kubernetes.io/docs/tutorials/security/apparmor/ for the `appArmorProfile` field and the legacy annotation
- `man 8 apparmor_parser`, `man 1 aa-status`, `man 5 apparmor.d`
