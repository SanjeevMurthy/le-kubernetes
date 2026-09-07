# Q37. The API server is down again: a volume is wrong (solution)

## Steps

Everything happens on the control-plane node, as root.

```bash
ssh <control-plane>
sudo -i
```

**1. Confirm the container is not merely crashing.**

```bash
crictl ps -a | grep kube-apiserver
```

There is no recent `kube-apiserver` container at all, or only an old `Exited` one from before the edit. A container that starts and dies leaves an `Exited` entry with a fresh timestamp and a readable log. Nothing here means the kubelet never got as far as creating it, so `crictl logs` has nothing to give you.

**2. Read the kubelet journal. That is where the reason is.**

```bash
journalctl -u kubelet -n 60 --no-pager | grep -i -A2 'volume\|kube-apiserver'
```

```
Error: cannot find volume "audit-typo" to mount into container "kube-apiserver"
```

Narrow it if the journal is noisy:

```bash
journalctl -u kubelet --since '-5 min' --no-pager | grep -i 'cannot find volume'
```

**3. Look at the mount the kubelet named, and at the volume list.**

```bash
grep -n -A2 'audit-typo' /etc/kubernetes/manifests/kube-apiserver.yaml
grep -n -A1 '^  volumes:' /etc/kubernetes/manifests/kube-apiserver.yaml
```

The container asks for a volume called `audit-typo` under `volumeMounts`. Nothing under `spec.volumes` declares it. Every mount has to name a volume that exists in the same pod.

**4. Remove the three lines of the orphan mount.**

```bash
vim /etc/kubernetes/manifests/kube-apiserver.yaml
```

Delete this block from `volumeMounts` and change nothing else:

```yaml
    - mountPath: /var/log/audit-typo
      name: audit-typo
      readOnly: true
```

There is a second correct answer: add the missing volume instead.

```yaml
  volumes:
  - hostPath:
      path: /var/log/audit-typo
      type: DirectoryOrCreate
    name: audit-typo
```

Both bring the API server back. Removing the mount is the right one here, because nothing in the cluster wanted that path in the first place, and a mount that nobody asked for is one more hostPath into the control plane.

**5. Wait for the static pod, then check the cluster.**

```bash
watch crictl ps
kubectl get nodes
kubectl get pods -n kube-system
```

Save, then wait. The kubelet rescans the directory about every 20 seconds and the container takes a few seconds more to become ready. If it is still down after a minute, read the journal again: a YAML indentation mistake made while deleting the block produces a different error, `failed to parse manifest`, and the pod is not even attempted.

## Why

A static pod is not admitted by the API server. The kubelet reads the file, validates it itself, and runs it. That is what makes this class of outage recoverable at all, and it is also why the error never appears in any Kubernetes object: there is no event, no pod status, no `kubectl describe`, because there is no API server to hold them.

Validation happens in stages, and the stage tells you where to look. A YAML syntax error is rejected at parse time, before a pod object exists. A structural error such as a `volumeMounts` entry with no matching volume is rejected when the kubelet builds the container's mounts, before the runtime is called, so no container is created and no container log exists. A bad flag or a bad certificate path is only found by the process itself, which starts, fails and exits, leaving an `Exited` container and a log worth reading.

So the diagnosis order for a dead control plane is fixed and worth memorising. `crictl ps -a` first: if a container exists, read its log with `crictl logs`, and the answer is in the process output. If no container exists, the kubelet refused it, and `journalctl -u kubelet` has the reason. Reading the manifest from top to bottom hoping to spot the mistake is the slow path, and on a file of 60 lines with 5 volumes and 30 flags it usually fails.

The four failures that account for nearly all of these are a misspelled flag, a mount with no matching volume, a `hostPath` that does not exist on the node, and a certificate or kubeconfig path that points somewhere wrong. All four look identical from the outside, and all four are one line in the journal.

## Verify

```bash
grep -c audit-typo /etc/kubernetes/manifests/kube-apiserver.yaml   # 0
crictl ps | grep kube-apiserver
curl -sk https://127.0.0.1:6443/readyz
kubectl get nodes
```

## Docs

**Allowed:** `https://kubernetes.io/docs/tasks/configure-pod-container/configure-volume-storage/` for the pairing of `volumes` and `volumeMounts`, and `https://kubernetes.io/docs/tasks/configure-pod-container/static-pod/` for how the kubelet picks a manifest up.

In practice this task is solved without documentation. What is needed is the habit: `crictl ps -a`, then `crictl logs` or `journalctl -u kubelet`, and only then the file.
