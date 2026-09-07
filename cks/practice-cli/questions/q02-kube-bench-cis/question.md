# Q2. CIS Benchmark Remediation with kube-bench

**Host:** the control-plane node named in the setup output (root shell: `sudo -i`).

A CIS Kubernetes Benchmark run on this node reports two failures: **1.2.1** — the API server accepts anonymous requests — and **4.2.4** — the kubelet serves an unauthenticated read-only port, which currently answers on `http://127.0.0.1:10255/pods`.

1. Remediate **CIS 1.2.1**: set `--anonymous-auth=false` in the kube-apiserver static pod manifest `/etc/kubernetes/manifests/kube-apiserver.yaml`, and wait until the API server is ready again (`curl -sk https://127.0.0.1:6443/readyz`).
2. Remediate **CIS 4.2.4**: set `readOnlyPort: 0` in `/var/lib/kubelet/config.yaml` and restart the kubelet, so that `curl -s --max-time 3 http://127.0.0.1:10255/pods` fails to connect.
3. Leave the kubelet service `active` and the API server serving, then confirm with `kube-bench run --targets node --check 4.2.4` that the check now reports `[PASS]`.
