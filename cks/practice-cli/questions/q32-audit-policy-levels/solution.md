# Q32. Audit: ordered policy and retention flags (solution)

## Steps

Everything happens on the control-plane node, as root.

**1. Back the manifest up outside the manifest directory.** A file left in `/etc/kubernetes/manifests/` with any extension is still read by the kubelet, so a backup written next to it can start a second API server.

```bash
cp /etc/kubernetes/manifests/kube-apiserver.yaml /root/kube-apiserver.yaml.bak
```

**2. Write the policy, in order.**

```bash
cat > /etc/kubernetes/audit/policy.yaml <<'EOF'
apiVersion: audit.k8s.io/v1
kind: Policy
omitStages:
  - "RequestReceived"
rules:
  # 1. The valuable reads, in full, before anything can suppress them.
  - level: RequestResponse
    namespaces: ["prod"]
    resources:
      - group: ""
        resources: ["secrets"]

  # 2. Health and metrics polling, dropped.
  - level: None
    nonResourceURLs:
      - "/healthz*"
      - "/version"
      - "/metrics"

  # 3. All remaining reads, dropped.
  - level: None
    verbs: ["get", "list", "watch"]

  # 4. Everything else at Metadata.
  - level: Metadata
EOF
```

**3. Add the five flags to the API server.**

```bash
vim /etc/kubernetes/manifests/kube-apiserver.yaml
```

```yaml
    - --audit-policy-file=/etc/kubernetes/audit/policy.yaml
    - --audit-log-path=/var/log/kubernetes/audit/audit.log
    - --audit-log-maxage=30
    - --audit-log-maxbackup=10
    - --audit-log-maxsize=100
```

**4. Add the mounts and the volumes in the same file.** Two entries under `volumeMounts:` and two under `volumes:`.

```yaml
    volumeMounts:
    - mountPath: /etc/kubernetes/audit/policy.yaml
      name: audit-policy
      readOnly: true
    - mountPath: /var/log/kubernetes/audit
      name: audit-log
      readOnly: false
```

```yaml
  volumes:
  - hostPath:
      path: /etc/kubernetes/audit/policy.yaml
      type: File
    name: audit-policy
  - hostPath:
      path: /var/log/kubernetes/audit
      type: DirectoryOrCreate
    name: audit-log
```

**5. Wait for the API server to come back.** The kubelet notices the changed manifest within about twenty seconds and recreates the Pod.

```bash
watch crictl ps | grep kube-apiserver
curl -sk https://127.0.0.1:6443/readyz
kubectl get nodes
```

If `kubectl` keeps refusing the connection, read the container log:

```bash
crictl ps -a | grep kube-apiserver
crictl logs <container-id> 2>&1 | tail -20
```

**6. Prove the ordering with traffic, not with the file.**

```bash
kubectl -n prod get secret db-creds
kubectl -n prod get pods
sleep 2
grep '"resource":"secrets"' /var/log/kubernetes/audit/audit.log | tail -1
grep '"resource":"pods"' /var/log/kubernetes/audit/audit.log | grep -c '"verb":"list"'   # 0
```

The secret read appears with `"level":"RequestResponse"` and a full `responseObject`. The pod list does not appear at all.

## Why

Audit rules are evaluated top to bottom and the first rule that matches decides the level for that request. That single sentence explains every part of this task. The `None` rule for `get`, `list` and `watch` is the noisiest thing in the policy: it drops the reads that make up most API traffic. If it were written above the secrets rule, it would also drop every read of every Secret, and the policy would record nothing about the one resource it was written to protect. The order is the control.

The `None` rule for the non-resource URLs sits between them because `/healthz` polling arrives several times a second from the kubelet and the load balancer. Those requests carry no `verbs` that the verb rule would catch reliably, so they need their own rule, and they need it before the catch-all turns each one into a `Metadata` line.

`RequestResponse` is the heaviest level, and it is the only one that stores the object that came back. For a Secret that means the value lands in the audit log in clear text, which is exactly why it is scoped to one resource in one namespace rather than applied broadly.

The four retention flags are what keeps the log from filling the disk on the control-plane node. `maxsize` rotates at 100 MB, `maxbackup` keeps ten rotated files, `maxage` deletes anything older than 30 days. An audit log that fills the root filesystem takes etcd down with it, so the flags are part of the answer, not decoration.

The two `hostPath` types differ because the two objects differ. The policy is a file that must already exist, so `type: File` makes the kubelet refuse to start the Pod if the path is wrong instead of silently mounting an empty directory over it. The log path is a directory the API server writes into, so `type: DirectoryOrCreate` is right there.

## Verify

```bash
grep -n 'level:' /etc/kubernetes/audit/policy.yaml     # RequestResponse, None, None, Metadata in that order
grep -n 'audit' /etc/kubernetes/manifests/kube-apiserver.yaml
curl -sk https://127.0.0.1:6443/readyz
kubectl -n prod get secret db-creds >/dev/null
kubectl -n prod get pods >/dev/null
grep '"level":"RequestResponse"' /var/log/kubernetes/audit/audit.log | grep -c '"resource":"secrets"'   # 1 or more
grep '"resource":"pods"' /var/log/kubernetes/audit/audit.log | grep -c '"verb":"list"'                 # 0
wc -l /var/log/kubernetes/audit/audit.log
```

## Docs

**Allowed:** `https://kubernetes.io/docs/tasks/debug/debug-cluster/audit/`. It carries a complete sample policy that can be copied and cut down, the full list of levels, and the `--audit-log-*` flags with their defaults. Search the page for "Audit policy" and take the example from there rather than typing one from memory.

The flag reference is at `https://kubernetes.io/docs/reference/command-line-tools-reference/kube-apiserver/`. What is worth memorising is the order rule, since no page states it as prominently as the exam relies on it: first match wins, so specific rules go above general ones and the catch-all goes last.
