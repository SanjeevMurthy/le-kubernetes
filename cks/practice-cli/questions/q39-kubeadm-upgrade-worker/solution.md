# Q39. Upgrade kubelet and kubectl on the worker to the latest patch (solution)

## Steps

**1. Read the target and the node name.**

```bash
cat ~/.cks-practice/q39.target        # for example 1.35.1
kubectl get nodes -o wide
```

**2. Drain the node.** This runs from the control plane, where `kubectl` still has its admin kubeconfig.

```bash
kubectl drain <worker> --ignore-daemonsets --delete-emptydir-data
kubectl get nodes
```

The node goes to `Ready,SchedulingDisabled`. `--ignore-daemonsets` is not optional: DaemonSet pods are not evictable and the drain refuses to start without it. `--delete-emptydir-data` is needed whenever a pod has an `emptyDir`, which on a lab cluster is most of them.

**3. Move to the worker and find the exact package version.**

```bash
ssh <worker>
sudo -i
apt-cache madison kubelet | head -5
```

```
   kubelet | 1.35.1-1.1 | https://pkgs.k8s.io/core:/stable:/v1.35/deb  Packages
   kubelet | 1.35.0-1.1 | https://pkgs.k8s.io/core:/stable:/v1.35/deb  Packages
```

The package version is `1.35.1-1.1`, not `1.35.1`. Apt wants the full string.

**4. Lift the pin, install, put the pin back.**

```bash
apt-mark unhold kubelet kubectl
apt-get update
apt-get install -y kubelet=1.35.1-1.1 kubectl=1.35.1-1.1
apt-mark hold kubelet kubectl
```

`apt-mark showhold` lists what is currently pinned. Forgetting to re-hold is the mistake that bites weeks later, when an unrelated `apt-get upgrade` walks the kubelet to a version the control plane cannot talk to.

**5. Restart the kubelet.**

```bash
systemctl daemon-reload
systemctl restart kubelet
systemctl status kubelet --no-pager | head -5
kubelet --version
kubectl version --client
```

**6. Put the node back into service**, from the control plane.

```bash
kubectl uncordon <worker>
kubectl get nodes -o wide
```

`kubectl get nodes` shows the new version in the VERSION column once the kubelet has re-registered, which takes a few seconds.

## Why

A kubeadm node is upgraded in two halves and it is worth keeping them apart in your head. `kubeadm upgrade` rewrites what the cluster holds: static pod manifests, certificates, the kubelet ConfigMap. The package manager replaces the binaries. Neither does the other's work, so a node whose packages were upgraded without a restart still runs the old kubelet, and a `kubeadm upgrade node` without new packages changes nothing about the binary.

The documented order for a worker is: upgrade the `kubeadm` package, run `kubeadm upgrade node`, drain the node, upgrade `kubelet` and `kubectl`, reload and restart the kubelet, uncordon. For a patch bump within the same minor version, `kubeadm upgrade node` only refreshes the local kubelet configuration from the cluster and changes nothing else, which is why it is left out above and is not graded here. Include it when the minor version moves, where it does real work.

The pin exists because these packages must not drift on their own. kubeadm holds `kubeadm`, `kubelet` and `kubectl` so that a routine `apt-get upgrade` cannot break the version skew rules. Lifting the hold for one deliberate install and putting it straight back is the whole ritual, and `--allow-change-held-packages` on the install is the shortcut for it.

Draining first is about the workload, not the kubelet. Restarting a kubelet does not stop the containers it manages, but the upgrade window is exactly when a node should not be taking new work, and on a real cluster the restart can be the moment a bad configuration is discovered. Cordon plus drain makes that discovery cheap. The step everyone forgets is `uncordon`: the node comes back Ready, nothing schedules onto it, and the cluster quietly loses a node. Both this verifier and a real exam check for it.

One honest caveat about the order used here. The skew rules say the kubelet must not be newer than the API server, so a real upgrade does the control plane first and the workers after. This task isolates the worker deliberately, and a patch-level difference in that direction is harmless in practice, but on an exam task that asks for both, upgrade the control plane first.

## Verify

```bash
kubectl get nodes -o wide
kubectl get node <worker> -o jsonpath='{.status.nodeInfo.kubeletVersion}{"\n"}'
kubectl get node <worker> -o jsonpath='{.spec.unschedulable}{"\n"}'   # empty
ssh <worker> kubelet --version
ssh <worker> apt-mark showhold
```

## Docs

**Allowed:** `https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/upgrading-linux-nodes/` is the page for this exact task and it can be followed line by line. Its neighbour, `https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/`, covers the control plane.

Reach the node page by searching kubernetes.io for "upgrade linux nodes". Memorise the shape of the command sequence anyway, because it is short and typing it beats reading it: drain, unhold, install, hold, daemon-reload, restart, uncordon.
