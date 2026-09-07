# Q34. AppArmor: the profile name is not the file name (solution)

<!-- toc -->
## Table of Contents

- [Steps](#steps)
- [Why](#why)
- [Verify](#verify)
- [Docs](#docs)

<!-- toc stop -->

## Steps

Everything happens on the worker node, as root.

```bash
ssh <worker>
sudo -i
```

**1. Read the profile file before touching anything.** This is the whole question.

```bash
cat /etc/apparmor.d/k8s-lab-deny-write
```

```
#include <tunables/global>
profile deny-write-lab flags=(attach_disconnected) {
  #include <abstractions/base>
  file,
  deny /** w,
}
```

The file is called `k8s-lab-deny-write`. The profile inside it is called **`deny-write-lab`**. Kubernetes wants the profile name, not the file name.

**2. Load the profile.**

```bash
apparmor_parser -q /etc/apparmor.d/k8s-lab-deny-write
```

`-q` loads or replaces quietly. `-r` also replaces an already loaded profile, and `-R` removes one.

**3. Confirm what name the kernel now knows.**

```bash
aa-status | grep deny
apparmor_status | head -5
```

The name in `aa-status` is `deny-write-lab`. There is no profile called `k8s-lab-deny-write` anywhere in the kernel, which is why the original Pod never started: the kubelet cannot find the profile the manifest asked for and leaves the Pod in `Blocked`, `CreateContainerError` or `Pending` depending on the version.

**4. Fix the manifest.**

```bash
vim /opt/course/34/pod.yaml
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: guarded
  namespace: apparmor-trap
spec:
  nodeName: <worker>
  containers:
  - name: guarded
    image: busybox:1.36
    command: ["sleep", "3600"]
    securityContext:
      appArmorProfile:
        type: Localhost
        localhostProfile: deny-write-lab
```

**5. Apply and watch it start.**

```bash
kubectl delete pod guarded -n apparmor-trap --ignore-not-found
kubectl apply -f /opt/course/34/pod.yaml
kubectl get pod guarded -n apparmor-trap -o wide
```

If it stays `Pending` or reports `CreateContainerError`, the reason is in the events:

```bash
kubectl describe pod guarded -n apparmor-trap | tail -15
```

**6. Test the effect.**

```bash
kubectl exec -n apparmor-trap guarded -- ls /root        # works, reads are allowed
kubectl exec -n apparmor-trap guarded -- touch /root/x   # Permission denied
```

The denial is also recorded on the node:

```bash
dmesg | grep -i apparmor | tail -5
journalctl -k | grep 'apparmor="DENIED"' | tail -5
```

## Why

An AppArmor profile has two names that people assume are the same one. The file under `/etc/apparmor.d/` is only a location on disk; the parser reads it and registers whatever comes after the `profile` keyword. `localhostProfile` in a Pod spec is matched against that registered name, so a manifest that names the file fails even though the file exists, is loaded, and is correct. This mismatch is the single most common way this task is failed, and it is worth building the habit of reading the profile's first line rather than the directory listing.

Loading is a separate step from writing. A profile file that has never been through `apparmor_parser` does nothing at all, and nothing in Kubernetes loads it for you: the kubelet only looks up profiles that are already in the kernel. On a multi-node cluster the profile has to be present and loaded on every node the Pod might land on, which is why the Pod here is pinned to one node with `nodeName`.

The failure mode is deliberately quiet. The Pod is accepted by the API server, because the API server does not know what profiles a node has. Only the kubelet on the target node discovers that the profile is missing, so the symptom appears as a Pod that never becomes ready and an event on that node, not as an error from `kubectl apply`.

## Verify

```bash
grep profile /etc/apparmor.d/k8s-lab-deny-write
aa-status | grep deny-write-lab
kubectl get pod guarded -n apparmor-trap -o jsonpath='{.spec.containers[0].securityContext.appArmorProfile.localhostProfile}'
kubectl get pod guarded -n apparmor-trap
kubectl exec -n apparmor-trap guarded -- ls /root
kubectl exec -n apparmor-trap guarded -- touch /root/x    # must fail
```

## Docs

**Allowed:** `https://kubernetes.io/docs/tutorials/security/apparmor/` for the `securityContext.appArmorProfile` fields and the older `container.apparmor.security.beta.kubernetes.io/<container>` annotation, which still appears in older exam clusters.

The AppArmor manual pages on the node cover the rest: `man apparmor_parser`, `man apparmor.d`, and `aa-status`. What has to be memorised is the relationship: `localhostProfile` takes the name declared after the `profile` keyword inside the file, and the file has to be loaded with `apparmor_parser` on the node the Pod runs on.
