# Q32. Audit: ordered policy and retention flags

**Host:** the control-plane node, root shell (`sudo -i`).

`/etc/kubernetes/audit/policy.yaml` exists but its `rules` list is empty. The directory `/var/log/kubernetes/audit/` exists. `kube-apiserver` currently has no `--audit-*` flags at all. Namespace `prod` holds Secret `db-creds`.

An audit policy is evaluated **first match wins**, so the order of the rules is part of the answer.

1. Write exactly these four rules into `/etc/kubernetes/audit/policy.yaml`, in this order:

   1. `secrets` in namespace `prod` at level `RequestResponse`
   2. the non-resource URLs `/healthz*`, `/version` and `/metrics` at level `None`
   3. every `get`, `list` and `watch` at level `None`
   4. a final catch-all at level `Metadata`

2. Wire the API server to that policy with all five audit flags:

   ```
   --audit-policy-file=/etc/kubernetes/audit/policy.yaml
   --audit-log-path=/var/log/kubernetes/audit/audit.log
   --audit-log-maxage=30
   --audit-log-maxbackup=10
   --audit-log-maxsize=100
   ```

3. Give the static Pod access to both paths:

   - the policy **file** `/etc/kubernetes/audit/policy.yaml` from a `hostPath` of `type: File`, mounted read-only
   - the log **directory** `/var/log/kubernetes/audit` from a `hostPath` of `type: DirectoryOrCreate`, mounted writable

4. The API server has to come back healthy and the log has to fill. Reading `db-creds` in `prod` must be recorded at `RequestResponse`, and listing pods must not be recorded at all.
