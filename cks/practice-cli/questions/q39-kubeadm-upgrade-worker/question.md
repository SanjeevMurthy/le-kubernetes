# Q39. Upgrade kubelet and kubectl on the worker to the latest patch

**Host:** the control-plane node for the `kubectl` steps, and a root shell on the worker node for the package steps.

The worker runs an older patch release of the kubelet than its package repositories offer. Setup printed the running version and the target version, and also wrote the target to `$CKS_STATE_DIR/q39.target` so you can read it back at any time:

```bash
cat ~/.cks-practice/q39.target
```

Upgrade that node, and only that node. The minor version does not change and the control plane is not touched.

1. Take the workload off the node and stop new pods being scheduled onto it.

2. Upgrade the `kubelet` and `kubectl` packages to the target version. On a kubeadm node both packages are pinned by apt, so the pin has to be lifted for the install and put back afterwards.

3. Reload systemd and restart the kubelet.

4. Put the node back into service.

At the end the node must be `Ready`, schedulable, and reporting the target version to the API server.
