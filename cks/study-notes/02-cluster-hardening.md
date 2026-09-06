# CKS Study Notes: Cluster Hardening (15%)

Domain 2 of the CKS curriculum. The published curriculum document is v1.34; the exam
environment runs Kubernetes v1.35, so write manifests and pick flags for v1.35. Every task
here is an access-control task, and the grader checks the effective permission rather than
the YAML that produced it. Three of the seven recipes touch
`/etc/kubernetes/manifests/kube-apiserver.yaml`, the most dangerous file on the exam.
Recipe 3 is the one to rehearse until the recovery sequence is automatic.

<!-- toc -->
## Table of Contents

- [What the exam asks](#what-the-exam-asks)
- [Recipe 1: Tighten an over-permissive Role and remove anonymous access](#recipe-1-tighten-an-over-permissive-role-and-remove-anonymous-access)
- [Recipe 2: Stop a pod from mounting a ServiceAccount token](#recipe-2-stop-a-pod-from-mounting-a-serviceaccount-token)
- [Recipe 3: Change an API server flag and recover when it does not come back](#recipe-3-change-an-api-server-flag-and-recover-when-it-does-not-come-back)
- [Recipe 4: Enable NodeRestriction and prove a kubelet is contained](#recipe-4-enable-noderestriction-and-prove-a-kubelet-is-contained)
- [Recipe 5: Upgrade a kubeadm cluster one minor version](#recipe-5-upgrade-a-kubeadm-cluster-one-minor-version)
- [Recipe 6: Issue a client certificate for a user through a CSR](#recipe-6-issue-a-client-certificate-for-a-user-through-a-csr)
- [Recipe 7: Read contexts and decode the certificate inside a kubeconfig](#recipe-7-read-contexts-and-decode-the-certificate-inside-a-kubeconfig)
- [Quick reference](#quick-reference)
- [Memorise](#memorise)

<!-- toc stop -->

## What the exam asks

| Task type | Sources | Drill |
|---|---|---|
| RBAC least privilege, roles, bindings, `auth can-i` | 10 | Q4, Q29 (planned) |
| API server flags: anonymous auth, authorization mode, NodeRestriction, NodePort | 9 | Q6, Q23 (planned), Q37 (planned) |
| kubeadm cluster upgrade, one minor version | 6 | Q39 (planned) |
| ServiceAccount hygiene, automount and token projection | 6 | Q5 |
| kubeconfig contexts and certificate extraction | 4 | Killercoda kubeconfig scenario |
| CSR and user certificates | 3 | Q40 (planned) |

Source counts come from the exam research table (task types 7, 9, 17, 18, 23, 26). RBAC and
apiserver flags together are close to a guaranteed appearance. The upgrade task is slow, so
flag it and come back to it once the cheaper tasks are banked.

## Recipe 1: Tighten an over-permissive Role and remove anonymous access

**Goal.** A named subject can do exactly the verbs the task lists on exactly the resources it
lists, and no binding grants anything to `system:anonymous` or `system:unauthenticated`.

**Frequency.** 10 candidate sources (see ../practice-tests/exam-questions/cks-real-exam-questions.md). Drill: Q4, Q29 (planned).

**Commands.**

```bash
# Namespaced least privilege. Imperative is faster and cannot mistype an apiGroup.
k create role pod-reader --verb=get,list,watch --resource=pods -n dev
k create rolebinding read-pods --role=pod-reader --serviceaccount=dev:app-sa -n dev

# A ClusterRole granted inside one namespace only, via a RoleBinding.
k create clusterrole secret-reader --verb=get --resource=secrets
k create rolebinding read-secrets --clusterrole=secret-reader --serviceaccount=dev:app-sa -n dev

# Fix an existing role: regenerate it rather than hand-editing a long rules list.
k get role web-role -n prod -o yaml > /root/web-role.bak.yaml
k create role web-role --verb=get --resource=pods -n prod --dry-run=client -o yaml > /root/web-role.yaml
k replace -f /root/web-role.yaml

# Find every binding that hands permissions to the unauthenticated identities.
k get clusterrolebinding -o wide | grep -E 'anonymous|unauthenticated'
k get rolebinding -A -o wide | grep -E 'anonymous|unauthenticated'
k delete clusterrolebinding anonymous-cluster-admin
```

**Verify.**

```bash
k auth can-i list pods --as=system:serviceaccount:dev:app-sa -n dev          # yes
k auth can-i delete pods --as=system:serviceaccount:dev:app-sa -n dev        # no
k auth can-i --list --as=system:serviceaccount:dev:app-sa -n dev
k auth can-i '*' '*' --as=system:anonymous                                    # no
curl -k https://127.0.0.1:6443/api/v1/namespaces/default/pods                 # 401 or 403
```

**Gotchas.**

- ServiceAccount subjects are written `system:serviceaccount:<namespace>:<name>` in `--as`, but as `--serviceaccount=<namespace>:<name>` in `kubectl create rolebinding`. Mixing the two forms is the most common wasted minute.
- `kubectl auth can-i` answers for the subject you name, not for you. Without `--as` you are testing your own admin kubeconfig and every answer is `yes`.
- Narrow the existing binding or role. Adding a second, tighter role next to an over-permissive one changes nothing, because RBAC is purely additive and never subtracts.
- A `RoleBinding` referencing a `ClusterRole` grants only inside its own namespace. A `ClusterRoleBinding` grants everywhere, including namespaces created later.

**Docs.** Search kubernetes.io for "Using RBAC Authorization" and "Role Based Access Control Good Practices".

## Recipe 2: Stop a pod from mounting a ServiceAccount token

**Goal.** The pod runs under a dedicated ServiceAccount and has no API credential inside the
container, or receives only a short-lived audience-bound projected token.

**Frequency.** 6 candidate sources (see ../practice-tests/exam-questions/cks-real-exam-questions.md). Drill: Q5.

**Commands.**

```bash
k create serviceaccount app-sa -n dev

# Disable automount for every pod that uses this ServiceAccount.
k patch serviceaccount app-sa -n dev -p '{"automountServiceAccountToken": false}'

# The same for the namespace default ServiceAccount, which unlabelled pods pick up.
k patch serviceaccount default -n dev -p '{"automountServiceAccountToken": false}'

# Mint a short-lived token on demand instead of mounting a permanent one.
k create token app-sa -n dev --duration=10m

# List which ServiceAccounts pods actually use, to spot unused ones.
k get pods -A -o custom-columns=NS:.metadata.namespace,POD:.metadata.name,SA:.spec.serviceAccountName
```

```yaml
# Pod-level setting wins over the ServiceAccount setting.
apiVersion: v1
kind: Pod
metadata: {name: app, namespace: dev}
spec:
  serviceAccountName: app-sa
  automountServiceAccountToken: false
  containers:
  - name: app
    image: nginx:1.27.1
    # When the workload does need a token, project a bound one instead:
    volumeMounts:
    - {name: sa-token, mountPath: /var/run/secrets/tokens, readOnly: true}
  volumes:
  - name: sa-token
    projected:
      sources:
      - serviceAccountToken: {path: token, audience: vault, expirationSeconds: 3600}
```

**Verify.**

```bash
k exec app -n dev -- ls /var/run/secrets/kubernetes.io/serviceaccount   # No such file or directory
k get pod app -n dev -o jsonpath='{.spec.serviceAccountName}{"\n"}'
k get serviceaccount app-sa -n dev -o jsonpath='{.automountServiceAccountToken}{"\n"}'
k exec app -n dev -- sh -c 'curl -sk https://kubernetes.default/api/v1/namespaces/dev/pods | head -5'
```

**Gotchas.**

- Changing `automountServiceAccountToken` does not affect running pods. Recreate the pod, or use `k replace --force -f pod.yaml`, or the exec check still finds the old token.
- The pod field overrides the ServiceAccount field in both directions. A pod with `automountServiceAccountToken: true` still gets a token from a ServiceAccount that disables it.
- Deleting the token Secret is not the answer on v1.35. Tokens are projected by the kubelet and there is no long-lived Secret to delete unless someone created one.
- Before deleting an unused ServiceAccount, confirm no pod references it with the custom-columns listing above.

**Docs.** Search kubernetes.io for "Configure Service Accounts for Pods" and "Managing Service Accounts".

## Recipe 3: Change an API server flag and recover when it does not come back

**Goal.** The API server runs with the required flags and answers `/readyz`, and a broken edit
is diagnosed and reverted rather than guessed at.

**Frequency.** 9 candidate sources (see ../practice-tests/exam-questions/cks-real-exam-questions.md). Drill: Q6, Q23 (planned), Q37 (planned).

**Commands.**

```bash
# 0. Root on the control plane node, then back up. Do this before touching the file, every time.
sudo -i
cp /etc/kubernetes/manifests/kube-apiserver.yaml /root/kube-apiserver.yaml.bak

# 1. Edit the static pod manifest.
vim /etc/kubernetes/manifests/kube-apiserver.yaml
```

```yaml
# Under spec.containers[0].command, the flags the exam seeds wrong:
    - --anonymous-auth=false
    - --authorization-mode=Node,RBAC
    - --enable-admission-plugins=NodeRestriction
    - --profiling=false
    - --audit-log-path=/var/log/kubernetes/audit/audit.log
# and the flag the exam asks to remove, so the apiserver Service is ClusterIP only:
#   - --kubernetes-service-node-port=31443
```

```bash
# 2. Save and watch the container cycle. The kubelet rescans the manifest directory
#    about every 20 seconds, so a correct edit needs waiting, not re-editing.
watch crictl ps
crictl ps | grep kube-apiserver

# 3. If kubectl still hangs after a minute, work the recovery sequence in this order.
journalctl -fu kubelet | grep -i apiserver        # catches "Could not process manifest file"
crictl ps -a | grep kube-apiserver                # find the exited container and its id
crictl logs --tail=50 <container-id>              # the flag or file the process rejected

# 4. When the container never started, crictl has no logs. Read the kubelet log directory,
#    newest first, and take the kube-apiserver entry.
ls -t /var/log/kubernetes/pods/ | grep kube-apiserver | head -1
ls -t /var/log/pods/ | grep kube-apiserver | head -1
cat /var/log/pods/kube-system_kube-apiserver-<node>_<uid>/kube-apiserver/*.log | tail -30

# 5. Last resort: restore the backup and start again from a known-good file.
cp /root/kube-apiserver.yaml.bak /etc/kubernetes/manifests/kube-apiserver.yaml
```

**Verify.**

```bash
curl -k https://127.0.0.1:6443/readyz                       # ok
k get --raw='/readyz?verbose'
k -n kube-system get pod kube-apiserver-<node> -o jsonpath='{.spec.containers[0].command}{"\n"}' | tr ' ' '\n' | grep anonymous
curl -k https://127.0.0.1:6443/api/v1/nodes                 # 401 once anonymous auth is off
```

**Gotchas.**

- Back up first. Recovery without `/root/kube-apiserver.yaml.bak` means reconstructing a 60-line command list under exam pressure, and the reports say that usually loses the whole question.
- The kubelet rescans `/etc/kubernetes/manifests` about every 20 seconds. Save once, then wait a full minute before concluding the edit failed. Repeated re-editing restarts the clock and hides which change broke it.
- Any flag that names a file needs a matching `volumeMounts` entry and a `volumes` entry with a `hostPath`. A missing volume is the top cause of a crash loop, and the log line says the file does not exist, not that a volume is missing.
- YAML indentation errors never reach the container. The kubelet rejects the manifest, `crictl ps -a` shows nothing new, and only `journalctl -fu kubelet` explains why. That is why the journal comes before `crictl` in the sequence.
- Moving the manifest out of `/etc/kubernetes/manifests` stops the API server entirely. Moving it back is fine; forgetting to move it back fails the task. Restarting the kubelet in a loop does not help and hides the log line.
- The exam host has no `jq`. Read command flags with `-o jsonpath` piped through `tr` and `grep`, as in the verify block.

**Docs.** Search kubernetes.io for "kube-apiserver" (the command reference), "Controlling Access to the Kubernetes API" and "Create static Pods".

## Recipe 4: Enable NodeRestriction and prove a kubelet is contained

**Goal.** The `NodeRestriction` admission plugin is enabled, and a kubelet credential can no
longer modify another node or set restricted labels on its own.

**Frequency.** 9 candidate sources (see ../practice-tests/exam-questions/cks-real-exam-questions.md). Drill: Q6.

**Commands.**

```bash
sudo -i
cp /etc/kubernetes/manifests/kube-apiserver.yaml /root/kube-apiserver.yaml.bak
vim /etc/kubernetes/manifests/kube-apiserver.yaml
```

```yaml
# NodeRestriction only takes effect when Node authorization is also on.
    - --authorization-mode=Node,RBAC
    - --enable-admission-plugins=NodeRestriction
```

```bash
# Run the negative tests with the kubelet identity, not the admin kubeconfig.
k --kubeconfig /etc/kubernetes/kubelet.conf get nodes
k --kubeconfig /etc/kubernetes/kubelet.conf label node <other-node> owner=attacker
k --kubeconfig /etc/kubernetes/kubelet.conf label node <own-node> node-restriction.kubernetes.io/zone=dmz
```

**Verify.**

```bash
k -n kube-system get pod kube-apiserver-<node> -o jsonpath='{.spec.containers[0].command}{"\n"}' | tr ' ' '\n' | grep NodeRestriction
# Both label attempts must fail with a Forbidden message naming the node identity:
k --kubeconfig /etc/kubernetes/kubelet.conf label node <other-node> owner=attacker 2>&1 | grep -i forbidden
```

**Gotchas.**

- `--enable-admission-plugins` is a single comma-separated list. Adding a second copy of the flag means only one of them is read, and the seeded plugins silently disappear.
- NodeRestriction without `Node` in `--authorization-mode` does very little. The two go together.
- The plugin restricts what a node identity may change, which means the credential in `/etc/kubernetes/kubelet.conf`. Testing with admin credentials proves nothing.
- Labels under the `node-restriction.kubernetes.io/` prefix are the ones a kubelet may never set on itself. Ordinary labels on its own Node object are still allowed.

**Docs.** Search kubernetes.io for "Admission Control in Kubernetes" (the NodeRestriction section) and "Using Node Authorization".

## Recipe 5: Upgrade a kubeadm cluster one minor version

**Goal.** The control plane and the named worker run the target version, all nodes are `Ready`,
and no node is left cordoned.

**Frequency.** 6 candidate sources (see ../practice-tests/exam-questions/cks-real-exam-questions.md). Drill: Q39 (planned).

**Commands.**

```bash
# Control plane node first. Read the target version off the task text.
sudo -i
kubectl drain <cp-node> --ignore-daemonsets --delete-emptydir-data

# The package repository is pinned per minor version, so point it at the new one.
sed -i 's|v1.34|v1.35|' /etc/apt/sources.list.d/kubernetes.list
apt-get update
apt-cache madison kubeadm | head -3

apt-mark unhold kubeadm && apt-get install -y kubeadm=1.35.1-1.1 && apt-mark hold kubeadm
kubeadm version
kubeadm upgrade plan
kubeadm upgrade apply v1.35.1

apt-mark unhold kubelet kubectl
apt-get install -y kubelet=1.35.1-1.1 kubectl=1.35.1-1.1
apt-mark hold kubelet kubectl
systemctl daemon-reload && systemctl restart kubelet
kubectl uncordon <cp-node>

# Worker node: drain from the control plane, then do the rest over ssh on the worker.
kubectl drain <worker> --ignore-daemonsets --delete-emptydir-data
ssh <worker>
sudo -i
sed -i 's|v1.34|v1.35|' /etc/apt/sources.list.d/kubernetes.list && apt-get update
apt-mark unhold kubeadm && apt-get install -y kubeadm=1.35.1-1.1 && apt-mark hold kubeadm
kubeadm upgrade node
apt-mark unhold kubelet kubectl
apt-get install -y kubelet=1.35.1-1.1 kubectl=1.35.1-1.1
apt-mark hold kubelet kubectl
systemctl daemon-reload && systemctl restart kubelet
exit
kubectl uncordon <worker>
```

**Verify.**

```bash
kubectl get nodes -o wide
kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.nodeInfo.kubeletVersion}{"\t"}{.spec.unschedulable}{"\n"}{end}'
kubectl -n kube-system get pods
kubeadm upgrade plan          # reports the cluster is already at the target
```

**Gotchas.**

- Order matters: drain, then `kubeadm`, then `kubeadm upgrade apply` on the control plane or `kubeadm upgrade node` on a worker, then `kubelet` and `kubectl`, then daemon-reload and restart, then uncordon. Upgrading the kubelet package before `kubeadm upgrade` runs leaves the node unhealthy.
- The control plane uses `kubeadm upgrade apply <version>` with a leading `v`. Workers and extra control-plane nodes use `kubeadm upgrade node` with no version argument.
- The kubernetes apt repository URL contains the minor version. Skipping the `sources.list.d` edit makes `apt-get install` report that the version is unavailable.
- Forgetting `kubectl uncordon` costs the mark even when every version string is right, and kubeadm refuses to skip a minor version. This is the slowest task in the domain, so flag it and return once the faster tasks are banked.

**Docs.** Search kubernetes.io for "Upgrading kubeadm clusters" and "Upgrading Linux nodes".

## Recipe 6: Issue a client certificate for a user through a CSR

**Goal.** A named user has an approved, signed client certificate, a kubeconfig context that
uses it, and exactly the permissions the task lists.

**Frequency.** 3 candidate sources (see ../practice-tests/exam-questions/cks-real-exam-questions.md). Drill: Q40 (planned).

**Commands.**

```bash
# The CN becomes the username, each O becomes a group.
openssl genrsa -out jane.key 2048
openssl req -new -key jane.key -subj "/CN=jane/O=developers" -out jane.csr

# The request field is the base64 of the CSR on a single line.
cat <<EOF | k apply -f -
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: jane
spec:
  request: $(base64 -w0 jane.csr)
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: 86400
  usages:
  - client auth
EOF

k certificate approve jane      # or: k certificate deny jane, when the task says to reject it
k get csr jane -o jsonpath='{.status.certificate}' | base64 -d > jane.crt

k config set-credentials jane --client-key=jane.key --client-certificate=jane.crt --embed-certs=true
k config set-context jane --cluster=kubernetes --user=jane --namespace=dev
k create rolebinding jane-read --role=pod-reader --user=jane -n dev   # role from Recipe 1
```

**Verify.**

```bash
k get csr jane -o jsonpath='{.status.conditions[*].type}{"\n"}'   # Approved
openssl x509 -in jane.crt -noout -subject -dates -issuer
k auth can-i list pods --as=jane -n dev                            # yes
k --context=jane get pods -n dev
```

**Gotchas.**

- `spec.request` must be a single base64 line. Use `base64 -w0`; a wrapped value makes the API server reject the CSR as malformed.
- `usages` must contain `client auth`, and `signerName` must be `kubernetes.io/kube-apiserver-client`. The `kubelet-serving` signer is a different task and its certificate will not log a user in.
- `.status.certificate` stays empty until the CSR is approved and the signing controller has run. Re-read it after a couple of seconds rather than assuming approval failed.
- Read whether the task wants approve or deny. Denying a request that should not be trusted is a valid and graded answer. Deleting and recreating the CSR object is safe if you get it wrong.

**Docs.** Search kubernetes.io for "Certificate Signing Requests" and "Certificates and Certificate Signing Requests".

## Recipe 7: Read contexts and decode the certificate inside a kubeconfig

**Goal.** The requested context names and the decoded certificate details are written to the
exact output paths the task gives.

**Frequency.** 4 candidate sources (see ../practice-tests/exam-questions/cks-real-exam-questions.md). Drill: Killercoda kubeconfig scenario, no repo question yet.

**Commands.**

```bash
# Context names, one per line, straight into the answer file.
k config get-contexts -o name > /opt/course/1/contexts
k config current-context

# Decode the client certificate of a named user out of the kubeconfig.
k config view --raw -o jsonpath='{.users[0].user.client-certificate-data}' | base64 -d > /opt/course/1/jane.crt
k config view --raw -o jsonpath='{.users[?(@.name=="jane")].user.client-certificate-data}' | base64 -d > /opt/course/1/jane.crt
openssl x509 -in /opt/course/1/jane.crt -noout -subject -dates -issuer

# Switch context, and confirm which cluster the current context points at.
k config use-context jane
k config view --minify -o jsonpath='{.clusters[0].cluster.server}{"\n"}'
```

**Verify.**

```bash
cat /opt/course/1/contexts
openssl x509 -in /opt/course/1/jane.crt -noout -subject
k config current-context
k --context=jane auth can-i list pods -n dev
```

**Gotchas.**

- `-o name` on `kubectl config get-contexts` prints only the names, with no header and no current-context asterisk. That is almost always the format the answer file wants.
- Read the deliverable line again before moving on. These tasks are graded on file contents at an exact path, so correct output in the wrong file scores nothing.
- `k config view` redacts certificate and key data. `--raw` is what makes the base64 appear, and `--minify` limits the output to the current context.
- The exam host has no `jq`, so parse kubeconfig with `-o jsonpath` and jsonpath filters as above, or with `yq` against the file directly.

**Docs.** Search kubernetes.io for "Organizing Cluster Access Using kubeconfig Files" and "Configure Access to Multiple Clusters".

## Quick reference

```bash
# RBAC
k create role NAME --verb=get,list,watch --resource=pods -n NS
k create rolebinding NAME --role=R --serviceaccount=NS:SA -n NS   # or --clusterrole=CR --user=jane
k auth can-i VERB RESOURCE --as=system:serviceaccount:NS:SA -n NS   # or --list --as=jane
k get clusterrolebinding -o wide | grep -E 'anonymous|unauthenticated'

# ServiceAccount
k patch sa SA -n NS -p '{"automountServiceAccountToken": false}'
k create token SA -n NS --duration=10m
k exec POD -n NS -- ls /var/run/secrets/kubernetes.io/serviceaccount

# API server, always in this order
cp /etc/kubernetes/manifests/kube-apiserver.yaml /root/kube-apiserver.yaml.bak
vim /etc/kubernetes/manifests/kube-apiserver.yaml
watch crictl ps
curl -k https://127.0.0.1:6443/readyz

# API server recovery, also in this order
journalctl -fu kubelet | grep -i apiserver
crictl ps -a | grep kube-apiserver
crictl logs <container-id>
ls -t /var/log/pods/ | grep kube-apiserver | head -1
cat /var/log/pods/kube-system_kube-apiserver-<node>_<uid>/kube-apiserver/*.log | tail -30
cp /root/kube-apiserver.yaml.bak /etc/kubernetes/manifests/kube-apiserver.yaml

# Upgrade
kubectl drain NODE --ignore-daemonsets --delete-emptydir-data
apt-mark unhold kubeadm && apt-get install -y kubeadm=1.35.1-1.1 && apt-mark hold kubeadm
kubeadm upgrade plan && kubeadm upgrade apply v1.35.1     # control plane
kubeadm upgrade node                                       # worker
systemctl daemon-reload && systemctl restart kubelet
kubectl uncordon NODE

# CSR and kubeconfig
openssl req -new -key jane.key -subj "/CN=jane/O=developers" -out jane.csr
base64 -w0 jane.csr
k certificate approve jane
k get csr jane -o jsonpath='{.status.certificate}' | base64 -d > jane.crt
k config get-contexts -o name
k config view --raw -o jsonpath='{.users[0].user.client-certificate-data}' | base64 -d
```

Flags worth knowing by heart on `kube-apiserver`:

| Flag | Secure value | Why the exam seeds it wrong |
|---|---|---|
| `--anonymous-auth` | `false` | direct CIS finding, easy mark |
| `--authorization-mode` | `Node,RBAC` | `AlwaysAllow` disables authorization entirely |
| `--enable-admission-plugins` | includes `NodeRestriction` | contains a compromised kubelet |
| `--profiling` | `false` | profiling endpoints leak internals |
| `--kubernetes-service-node-port` | absent | its presence exposes the API on a NodePort |
| `--client-ca-file` | `/etc/kubernetes/pki/ca.crt` | needed for the CSR-issued client certificates |

## Memorise

- Back up `/etc/kubernetes/manifests/kube-apiserver.yaml` to `/root/` before the first keystroke of any apiserver task. Every other recovery step assumes that file exists.
- The kubelet rescans the manifest directory about every 20 seconds. After a save, wait a full minute. Do not re-edit and do not restart the kubelet repeatedly.
- Recovery order: kubelet journal filtered for apiserver, then `crictl ps -a`, then `crictl logs`, then the newest kube-apiserver directory under `/var/log/pods` or `/var/log/kubernetes/pods`, then restore the backup.
- Any apiserver flag naming a file needs both a `volumeMounts` entry and a `volumes` entry with a `hostPath`.
- ServiceAccount subject spelling: `--serviceaccount=ns:sa` when creating a binding, `--as=system:serviceaccount:ns:sa` when testing it.
- RBAC is additive only. To reduce access, narrow or delete the existing rule; never add a tighter one beside it.
- Pod-level `automountServiceAccountToken` overrides the ServiceAccount setting, and neither affects a running pod.
- CSR essentials: `signerName: kubernetes.io/kube-apiserver-client`, `usages: [client auth]`, `request` as single-line `base64 -w0`, CN is the user and O is the group.
- Upgrade order: drain, kubeadm, upgrade apply or upgrade node, kubelet and kubectl, daemon-reload and restart, uncordon.
- NodeRestriction needs `Node` in `--authorization-mode` to mean anything, and is tested with `/etc/kubernetes/kubelet.conf`, not the admin kubeconfig.
- There is no `jq` on the exam hosts. Parse with `-o jsonpath`, `-o custom-columns`, `yq`, `grep` and `tr`.
