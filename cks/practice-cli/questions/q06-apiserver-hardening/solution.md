# Q6. Restrict the API Server (apiserver flags) (solution)

## Steps

Three flags in one file. The file is the API server's own static pod manifest, so saving it restarts the control plane, and a typo stops it coming back. Back it up first; that is not caution, it is the difference between a two-minute task and a lost exam.

```bash
ssh <control-plane>
sudo -i
hostname
cp /etc/kubernetes/manifests/kube-apiserver.yaml /root/kube-apiserver.yaml.bak
```

**1. See the current state.** Confirm which flags are actually present, since some may be absent rather than wrong, and an absent flag is added rather than edited.

```bash
grep -E 'anonymous-auth|authorization-mode|profiling' /etc/kubernetes/manifests/kube-apiserver.yaml
```

**2. Make all three edits in one pass.** One save, one restart. Editing three times means three restarts and three chances to be caught mid-restart.

```bash
vi /etc/kubernetes/manifests/kube-apiserver.yaml
```

Under `spec.containers[0].command`:

```yaml
    - --anonymous-auth=false
    - --authorization-mode=Node,RBAC
    - --profiling=false
```

`Node,RBAC` in that order and with no spaces. `Node` is the authorizer that restricts each kubelet to the objects its own Pods need; `RBAC` is everything else. Leaving `AlwaysAllow` anywhere in the list defeats both, because the authorizers are consulted in order and the first one to allow wins.

**3. Watch it come back.** The kubelet notices the changed file within about twenty seconds and restarts the pod. `kubectl` will not answer during that window, which is normal and not a sign that you broke it.

```bash
until curl -sk https://127.0.0.1:6443/readyz | grep -q ok; do sleep 2; done
echo "ready"
kubectl get --raw=/version
```

**4. Prove the hardening, rather than reading it back.**

```bash
# an unauthenticated request must now be refused
curl -sk -o /dev/null -w '%{http_code}\n' https://127.0.0.1:6443/api
```

`401` or `403` is the pass. A `200` means `--anonymous-auth=false` did not take effect, which usually means the file was saved but the pod has not restarted yet.

```bash
# the flags the running process actually has, which is the only authority
crictl inspect "$(crictl ps --name kube-apiserver -q)" \
  | grep -E 'anonymous-auth|authorization-mode|profiling'
```

Reading the running process rather than the file catches the case where the manifest is correct and the old pod is still up.

## If it does not come back

`kubectl` is gone, so the cluster cannot tell you what went wrong. The node can, and this is worth being able to do from memory.

```bash
crictl ps -a | grep kube-apiserver          # look for Exited
crictl logs "$(crictl ps -a --name kube-apiserver -q | head -1)" 2>&1 | tail -30

# works even when crictl does not
ls -t /var/log/pods/kube-system_kube-apiserver-*/kube-apiserver/
tail -30 /var/log/pods/kube-system_kube-apiserver-*/kube-apiserver/*.log
```

What the three common failures look like:

- `unknown flag: --anonymous-auth` — misspelled, or a stray space before `--`.
- `error converting YAML to JSON` — the indentation of the list item moved.
- the pod never appears at all — the manifest is not valid YAML, so the kubelet never created it. `grep -c '^' ` the file and look at what you saved.

Restore and start again rather than debugging under time pressure:

```bash
cp /root/kube-apiserver.yaml.bak /etc/kubernetes/manifests/kube-apiserver.yaml
until curl -sk https://127.0.0.1:6443/readyz | grep -q ok; do sleep 2; done
```

Q23 and Q37 drill exactly this recovery, on purpose, from two different breakages.

## What each flag does

- `--anonymous-auth=false` rejects requests that carry no credentials. Anonymous requests arrive as user `system:anonymous` in group `system:unauthenticated`, and any RoleBinding to either is an open door. Q29 is the question about finding those bindings.
- `--authorization-mode=Node,RBAC` replaces `AlwaysAllow`, which authorizes every request from every authenticated caller and makes the whole of RBAC decorative.
- `--profiling=false` closes `/debug/pprof`, which otherwise exposes heap and goroutine dumps to anyone who can reach the port. It is CIS 1.2.18 and appears in kube-bench output.

## Gotchas

- Edit the file on the node. `kubectl edit` does not work on a static pod; the file is the source of truth and the API object is a mirror of it.
- Every save restarts the API server. Make all the edits, then save once.
- The INSERT key is disabled on the exam desktop. Use `i`.
- `--authorization-mode` is a comma-separated list with no spaces, and order matters.
- Flags may be absent rather than wrong. Adding a line is as valid an answer as changing one.
- Do not harden beyond what was asked. A cluster with extra flags and a dead API server scores worse than one with three correct edits.

## Docs

`kubernetes.io/docs` is allowed and the reference page lists every flag with its default.

- https://kubernetes.io/docs/reference/command-line-tools-reference/kube-apiserver/
- https://kubernetes.io/docs/reference/access-authn-authz/authorization/ for the authorizer chain and how `Node` and `RBAC` combine
