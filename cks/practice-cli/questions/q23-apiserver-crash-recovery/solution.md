# Q23. The API server is down: find and fix the manifest (solution)

<!-- toc -->
## Table of Contents

- [Steps](#steps)
- [Why](#why)
- [Verify](#verify)
- [Docs](#docs)

<!-- toc stop -->

## Steps

Everything happens on the control-plane node, as root.

**1. Confirm the API server is really the problem.**

```bash
kubectl get nodes
curl -sk --max-time 3 https://127.0.0.1:6443/readyz ; echo "exit=$?"
systemctl is-active kubelet
```

The kubelet is active and port 6443 refuses the connection, so the static pod is not running. That already rules out a network or certificate problem.

**2. Find the container, including the ones that have exited.** `crictl ps` on its own hides a container that keeps crashing, which is exactly the case here. `-a` is what makes it visible.

```bash
crictl ps -a | grep kube-apiserver
```

The output shows an `Exited` container with a rising attempt count.

**3. Read its output.**

```bash
crictl logs <container-id>
```

```
Error: unknown flag: --authorization-modes
```

That one line is the whole diagnosis. If `crictl logs` returns nothing because the container was already garbage collected, the same text is on disk and in the kubelet journal:

```bash
ls -t /var/log/pods/kube-system_kube-apiserver-*/kube-apiserver/
tail -20 /var/log/pods/kube-system_kube-apiserver-*/kube-apiserver/*.log
journalctl -u kubelet -n 50 --no-pager | grep -i apiserver
```

**4. Fix the flag.** The correct spelling is singular, `--authorization-mode`, and it takes a comma-separated list.

```bash
cp /etc/kubernetes/manifests/kube-apiserver.yaml /root/kube-apiserver.yaml.broken
vim /etc/kubernetes/manifests/kube-apiserver.yaml
```

```yaml
    - --authorization-mode=Node,RBAC
```

`sed` does the same edit in one line:

```bash
sed -i 's|--authorization-modes=|--authorization-mode=|' /etc/kubernetes/manifests/kube-apiserver.yaml
grep authorization /etc/kubernetes/manifests/kube-apiserver.yaml
```

**5. Wait for the kubelet to pick the change up.** It rescans the manifest directory about every 20 seconds. Nothing needs restarting.

```bash
watch crictl ps
```

When the container stops cycling and stays `Running`, the cluster is back:

```bash
curl -sk https://127.0.0.1:6443/readyz
kubectl get nodes
kubectl -n kube-system get pod -l component=kube-apiserver
```

If it still does not start, the manifest has a second problem. Read the logs again rather than guessing, and remember that a manifest which is not valid YAML produces no container at all, so `crictl ps -a` shows nothing new and the parse error appears only in the kubelet journal.

## Why

The API server on a kubeadm cluster is a static pod. No controller manages it. The kubelet reads `/etc/kubernetes/manifests/`, and whatever is in there is what runs, which is why a single wrong character in that file takes the entire control plane down and why nothing repairs it automatically.

This creates the diagnostic problem the question is really about. Every tool normally used to inspect a cluster goes through the API server, so when the API server is the thing that is broken, all of them are gone at once. The tools that still work are the ones that talk to the container runtime directly. `crictl ps -a` lists containers from containerd without involving Kubernetes at all, and `crictl logs` reads their output the same way. The kubelet journal is the other independent source, because the kubelet writes there whether or not it can reach the API server.

`crictl ps` without `-a` is the trap. A crash-looping container is exited by the time the command runs, so the listing comes back empty and the natural conclusion is that the pod was never created. The container is there, it has simply already died, and `-a` shows it along with the attempt count that says it is looping rather than merely stopped.

The failure mode itself is worth recognising by shape rather than by content. `unknown flag` means the process started and rejected its arguments, so the fault is in the command line in the manifest. A file-not-found error means a path is wrong or a `hostPath` volume is missing, so the fault is in the mounts. A YAML parse error in the kubelet journal with no container at all means the manifest itself does not load. Those three shapes cover almost every way a control plane is lost during this exam, and the recovery in every case is to read the log before touching the file.

## Verify

```bash
grep -- '--authorization-mode' /etc/kubernetes/manifests/kube-apiserver.yaml
grep -c -- '--authorization-modes' /etc/kubernetes/manifests/kube-apiserver.yaml   # 0
curl -sk --max-time 5 https://127.0.0.1:6443/readyz
kubectl get nodes
kubectl -n kube-system get pod -l component=kube-apiserver
```

## Docs

**Allowed:** `https://kubernetes.io/docs/reference/command-line-tools-reference/kube-apiserver/` lists every API server flag with its exact spelling, which settles `--authorization-mode` against `--authorization-modes` in a few seconds.

The recovery procedure itself has to be memorised, because no page will help while the API server is down. Three commands are enough: `crictl ps -a` to find the container including exited ones, `crictl logs <id>` to read why it exited, and `journalctl -u kubelet` when there is no container to inspect. Know the manifest path `/etc/kubernetes/manifests/kube-apiserver.yaml` and the log path `/var/log/pods/` by heart, and copy the manifest before editing it so an unsuccessful attempt can be undone.
