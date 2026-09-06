# Q17. API Server Audit Logging Policy

**Host:** the control-plane node, as root (`ssh` to the control plane, then `sudo -i`).

Auditing is switched off on this cluster. `kube-apiserver` runs with no `--audit-*` flags, and
the policy file `/etc/kubernetes/audit/policy.yaml` exists but its `rules:` list is empty. The
log directory `/var/log/kubernetes/audit` has already been created for you.

1. Complete `/etc/kubernetes/audit/policy.yaml` so that, evaluated in order, it:
   - logs access to `secrets` at level `RequestResponse`,
   - drops read-only noise (`get`, `list`, `watch`) at level `None`,
   - logs everything else at level `Metadata`.
2. Wire the policy into `kube-apiserver` in `/etc/kubernetes/manifests/kube-apiserver.yaml`:
   - `--audit-policy-file=/etc/kubernetes/audit/policy.yaml`
   - `--audit-log-path=/var/log/kubernetes/audit/audit.log`
   Add the matching `volumes` and `volumeMounts` for `/etc/kubernetes/audit` (read-only) and
   `/var/log/kubernetes/audit` (writable), or the API server will not come back up.
3. Bring the API server back to ready and confirm that `/var/log/kubernetes/audit/audit.log`
   grows when Secrets are read.
