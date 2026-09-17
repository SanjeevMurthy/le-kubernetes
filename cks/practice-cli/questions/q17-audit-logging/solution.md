# Q17. API Server Audit Logging Policy (solution)

## Steps

This task edits the API server's own static pod manifest. Every save restarts the API server, and a mistake takes the cluster's control plane down until you fix it. Work on the control plane, as root, and back the manifest up before touching it.

```bash
ssh <control-plane>
sudo -i
hostname
cp /etc/kubernetes/manifests/kube-apiserver.yaml /root/kube-apiserver.yaml.bak
```

**1. Write the policy, in order.** An audit policy is evaluated top to bottom and the **first matching rule wins**. That single fact is the whole question: the same three rules in a different order produce a policy that logs nothing useful.

```bash
cat > /etc/kubernetes/audit/policy.yaml <<'EOF'
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
# 1. Secrets first, at the loudest level, or a later rule would catch them.
- level: RequestResponse
  resources:
  - group: ""
    resources: ["secrets"]

# 2. Then drop the read-only noise. This is what keeps the log readable.
- level: None
  verbs: ["get", "list", "watch"]

# 3. Everything left over.
- level: Metadata
EOF
```

Put the `None` rule above the `secrets` rule and reads of Secrets stop being logged, which is exactly the access the question exists to capture. Put the bare `Metadata` rule first and nothing below it ever runs.

**2. Check it parses before the API server does.** There is no linter for this, so read it back and confirm the shape is what you intended.

```bash
yq -P '.rules[] | {"level": .level, "verbs": .verbs, "resources": .resources}' \
  /etc/kubernetes/audit/policy.yaml
```

**3. Wire it into the manifest.** Four things must be added, and forgetting any one of them is the reported failure mode.

```bash
vi /etc/kubernetes/manifests/kube-apiserver.yaml
```

The flags, under `spec.containers[0].command`:

```yaml
    - --audit-policy-file=/etc/kubernetes/audit/policy.yaml
    - --audit-log-path=/var/log/kubernetes/audit/audit.log
```

The mounts, under `spec.containers[0].volumeMounts`:

```yaml
    - name: audit-policy
      mountPath: /etc/kubernetes/audit
      readOnly: true
    - name: audit-logs
      mountPath: /var/log/kubernetes/audit
      readOnly: false
```

And the volumes, under `spec.volumes`:

```yaml
  - name: audit-policy
    hostPath:
      path: /etc/kubernetes/audit
      type: DirectoryOrCreate
  - name: audit-logs
    hostPath:
      path: /var/log/kubernetes/audit
      type: DirectoryOrCreate
```

The API server runs as a container. Without the mounts it cannot see a policy file that plainly exists on the node, and it exits on startup complaining about a path you are looking straight at. `readOnly: false` on the log mount is not decoration: with the default the API server cannot create its own log file and refuses to start.

**4. Wait for it to come back.** Saving the file is not the end of the task. The kubelet notices the changed manifest within about twenty seconds and restarts the pod.

```bash
watch crictl ps | grep kube-apiserver

# or, once the API is answering again
kubectl -n kube-system get pod -l component=kube-apiserver
```

**5. Prove the log grows on the traffic it is supposed to catch.**

```bash
wc -l /var/log/kubernetes/audit/audit.log
kubectl get secrets -A >/dev/null
wc -l /var/log/kubernetes/audit/audit.log      # must be larger
```

And confirm the level is the one asked for, not just that something was written:

```bash
grep '"resource":"secrets"' /var/log/kubernetes/audit/audit.log | tail -1 \
  | yq -P '.level, .verb, .user.username'
```

## When the API server does not come back

This is the recovery drill, and it is worth being able to do it without thinking. `kubectl` is gone, so the cluster cannot tell you what is wrong. The node can.

```bash
# The container tried to start and died. Its logs say why.
crictl ps -a | grep kube-apiserver
crictl logs <container-id> 2>&1 | tail -30

# Or straight from disk, which works even when crictl does not
ls -t /var/log/pods/kube-system_kube-apiserver-*/kube-apiserver/
tail -30 /var/log/pods/kube-system_kube-apiserver-*/kube-apiserver/*.log
```

Nearly every failure here reads as one of: `unknown flag`, a YAML indentation error in the manifest, or the policy file not being visible inside the container. If you cannot see it in a minute, restore the backup, confirm the cluster is healthy, and redo the edit:

```bash
cp /root/kube-apiserver.yaml.bak /etc/kubernetes/manifests/kube-apiserver.yaml
```

Q23 and Q37 are the questions that drill this recovery on purpose.

## The four levels

Worth reciting, because the exam asks for them by name and there is no way to derive them:

| Level | What is written |
|---|---|
| `None` | nothing; the request is dropped from the log |
| `Metadata` | who, what, when, from where. No bodies |
| `Request` | the above plus the request body |
| `RequestResponse` | the above plus the response body |

`RequestResponse` on Secrets means the Secret's contents land in a plaintext log file, which is the right answer to the exam question and a decision worth making deliberately in real life.

## Gotchas

- First match wins. Order the rules narrowest to broadest.
- `resources` takes a `group` per entry, and the core group is `""`, not `"core"` and not omitted.
- Retention flags are separate and often asked for in the same breath: `--audit-log-maxage=30`, `--audit-log-maxbackup=10`, `--audit-log-maxsize=100`. Q32 drills those.
- `type: DirectoryOrCreate` on the hostPath. Without a type the kubelet will not create a missing directory and the pod stays pending.
- Editing with `kubectl edit` does not work here. This is a static pod; the file on the node is the source of truth, and the API object is a mirror.
- The INSERT key is disabled on the exam desktop. Use `i` in vim.

## Docs

`kubernetes.io/docs` is allowed, and this page carries a complete example policy worth knowing how to find quickly.

- https://kubernetes.io/docs/tasks/debug/debug-cluster/audit/
- https://kubernetes.io/docs/reference/config-api/apiserver-audit.v1/ for the Policy schema
