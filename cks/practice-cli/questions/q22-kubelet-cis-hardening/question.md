# Q22. kube-bench: fix the kubelet findings

`ssh` to the worker node and work as root. The kubelet on that node is configured from `/var/lib/kubelet/config.yaml`.

An audit ran `kube-bench` against the node and three kubelet checks in section 4.2 came back `[FAIL]`:

- **4.2.1** the kubelet accepts anonymous requests
- **4.2.2** the kubelet authorizes every request without asking the API server
- **4.2.4** the kubelet serves an unauthenticated read-only port

1. Re-run the audit yourself to see the findings and the remediation text:

   ```
   kube-bench run --targets node --check 4.2.1,4.2.2,4.2.4
   ```

2. Fix all three findings in `/var/lib/kubelet/config.yaml`. Set anonymous authentication to `false`, set the authorization mode to `Webhook`, and set `readOnlyPort` to `0` explicitly rather than deleting the key.

3. Restart the kubelet so the changes take effect.

4. The node must go back to `Ready`, and re-running the same `kube-bench` command must report `[PASS]` for all three checks.

Do not edit anything under `/etc/kubernetes/manifests/` for this question. Everything is in the kubelet configuration file.
