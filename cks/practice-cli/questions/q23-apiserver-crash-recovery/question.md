# Q23. The API server is down: find and fix the manifest

`ssh` to the control-plane node and work as root.

A change was made to the `kube-apiserver` static pod and the cluster has been unreachable since. Every `kubectl` command now returns a connection error:

```
The connection to the server 127.0.0.1:6443 was refused - did you specify the right host or port?
```

The kubelet is running and it keeps trying to start the pod. Nothing else on the node was touched.

1. Diagnose the failure without `kubectl`. The container runtime and the kubelet journal are the only sources of truth while the API server is down:

   ```
   crictl ps -a | grep kube-apiserver
   crictl logs <container-id>
   journalctl -u kubelet -n 50 --no-pager
   ```

   You can also read the container's own output under `/var/log/pods/kube-system_kube-apiserver-*/kube-apiserver/`.

2. Repair `/etc/kubernetes/manifests/kube-apiserver.yaml`. Change nothing except what is broken, and keep the authorization modes the cluster had before, `Node` and `RBAC`.

3. Wait for the static pod to come back and confirm that the cluster is usable again:

   ```
   crictl ps | grep kube-apiserver
   kubectl get nodes
   ```

The kubelet rescans `/etc/kubernetes/manifests/` roughly every 20 seconds, so give it up to a minute after saving before deciding the fix did not work.
