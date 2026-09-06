# Q2. CIS Benchmark Remediation with kube-bench (solution)

**Concept & Explanation:**

`kube-bench` checks your cluster's configuration against the CIS Benchmark, emitting PASS/WARN/FAIL with remediation text. Most FAILs map to a flag in a static-pod manifest (`/etc/kubernetes/manifests/`) or the kubelet config (`/var/lib/kubelet/config.yaml`). You fix the config, restart the affected component, and re-run.

**Solution — Step by Step:**

```bash
# See the two findings first
kube-bench run --targets master --check 1.2.1
kube-bench run --targets node   --check 4.2.4
# or as a Job:  kubectl apply -f https://raw.githubusercontent.com/aquasecurity/kube-bench/main/job.yaml

# Fix CIS 1.2.1 — apiserver anonymous-auth (edit the static pod manifest):
sudo cp /etc/kubernetes/manifests/kube-apiserver.yaml /tmp/kas.bak
sudo sed -i 's/--anonymous-auth=true/--anonymous-auth=false/' \
  /etc/kubernetes/manifests/kube-apiserver.yaml   # or add the flag if missing
curl -sk https://127.0.0.1:6443/readyz            # wait for 'ok'

# Fix CIS 4.2.4 — kubelet read-only port:
sudo vi /var/lib/kubelet/config.yaml      # set: readOnlyPort: 0
sudo systemctl restart kubelet

# Re-verify (the port must stop answering, and 4.2.4 must PASS)
curl -s --max-time 3 http://127.0.0.1:10255/pods  # connection refused
kube-bench run --targets node --check 4.2.4 | grep '\[PASS\]'
```

**Key Points to Remember:**

- FAIL items come with a **Remediation** block — read it; it tells you the exact flag/file.
- apiserver/scheduler/controller-manager fixes go in `/etc/kubernetes/manifests/*` (auto-restart); kubelet fixes go in `/var/lib/kubelet/config.yaml` then `systemctl restart kubelet`.
- Back up any manifest before editing.

**Official Documentation:**
- https://github.com/aquasecurity/kube-bench
- https://kubernetes.io/docs/concepts/security/security-checklist/

---
