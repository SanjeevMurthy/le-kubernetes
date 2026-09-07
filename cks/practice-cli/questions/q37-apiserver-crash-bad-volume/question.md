# Q37. The API server is down again: a volume is wrong

**Host:** the control-plane node, root shell (`sudo -i`).

Someone edited the `kube-apiserver` static pod and the cluster has been unreachable since. Every command returns:

```
The connection to the server 127.0.0.1:6443 was refused - did you specify the right host or port?
```

This one does not look like the last outage. The container never starts at all, so it writes no log of its own: `crictl logs` has nothing to show you. The kubelet is the component that refused it, so the kubelet is where the reason is.

1. Find the reason without `kubectl`:

   ```
   journalctl -u kubelet -n 60 --no-pager
   crictl ps -a | grep kube-apiserver
   ```

2. Fix `/etc/kubernetes/manifests/kube-apiserver.yaml`. Change only what is broken. Every flag, mount and volume that was there before has to still be there afterwards.

3. Wait for the static pod to come back and confirm the cluster works:

   ```
   crictl ps | grep kube-apiserver
   kubectl get nodes
   ```

The kubelet rescans `/etc/kubernetes/manifests/` about every 20 seconds, so give it up to a minute after saving before deciding the fix did not work.
