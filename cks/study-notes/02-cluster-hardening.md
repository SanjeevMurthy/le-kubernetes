# CKS Study Notes — Cluster Hardening (15%)

> Part of the CKS study-notes set; order follows the official CKS curriculum (v1.34, Kubernetes 1.34).
> Goal: understand each topic well enough to do the task fast under exam time pressure — not exhaustively.

**What the examiner tests here:** Writing least-privilege RBAC and proving it with `auth can-i`, locking down ServiceAccount tokens, hardening the API server via flags (and recovering when an edit breaks it), and keeping the cluster current.

---

## RBAC: Least-Privilege Roles & Bindings

**Why it matters:** RBAC is the primary access-control mechanism in Kubernetes; over-broad roles are the most common real-world (and exam) finding. Expect tasks to *create* a tight role or *fix* one that grants too much.

**Concepts**
- `Role`/`RoleBinding` are namespaced; `ClusterRole`/`ClusterRoleBinding` are cluster-wide. A `ClusterRole` can also be referenced by a `RoleBinding` to grant it in just one namespace.
- A rule = `apiGroups` + `resources` + `verbs` (+ optional `resourceNames`). Core API group is `""`.
- Subjects: `User`, `Group`, `ServiceAccount`. Bindings link subjects → role.
- Least privilege = narrowest verbs (`get,list,watch` not `*`), specific resources, specific namespace.

**Commands & examples**

```bash
# Imperative is fastest under time pressure:
kubectl create role pod-reader --verb=get,list,watch --resource=pods -n dev
kubectl create rolebinding read-pods \
  --role=pod-reader --serviceaccount=dev:app-sa -n dev

# ClusterRole granted in a single namespace via RoleBinding:
kubectl create clusterrole secret-reader --verb=get --resource=secrets
kubectl create rolebinding read-secrets \
  --clusterrole=secret-reader --serviceaccount=dev:app-sa -n dev

# VERIFY — the single most important RBAC command:
kubectl auth can-i get pods --as=system:serviceaccount:dev:app-sa -n dev   # -> yes
kubectl auth can-i delete pods --as=system:serviceaccount:dev:app-sa -n dev # -> no
kubectl auth can-i --list --as=system:serviceaccount:dev:app-sa -n dev
```

**⚠️ Exam tips:** Always confirm with `auth can-i --as=system:serviceaccount:<ns>:<sa>` — the task is usually graded on the effective permission, not the YAML. To *fix* an over-permissioned binding, narrow the `verbs`/`resources` or rebind to a tighter role; don't just add a second role. `resourceNames` restricts to named objects (e.g., one specific secret).

---

## ServiceAccount Token Hardening

**Why it matters:** A mounted SA token is a credential an attacker can steal from a compromised pod. Disabling automount and scoping tokens shrinks the blast radius.

**Concepts**
- Every pod gets the namespace `default` SA unless told otherwise — give workloads their own SA.
- `automountServiceAccountToken: false` stops the token from being mounted (set on the SA and/or the pod; pod-level wins).
- Modern tokens are short-lived **projected** tokens (bound audience + expiry), not the legacy forever-Secret.

**Commands & examples**

```bash
kubectl create serviceaccount app-sa -n dev

# Disable automount on the SA
kubectl patch serviceaccount app-sa -n dev \
  -p '{"automountServiceAccountToken": false}'
```
```yaml
# Or per-pod (overrides the SA setting):
apiVersion: v1
kind: Pod
metadata: {name: app, namespace: dev}
spec:
  serviceAccountName: app-sa
  automountServiceAccountToken: false   # pod has no API token mounted
  containers:
  - name: app
    image: nginx
```
```bash
# Mint a short-lived token on demand instead of mounting one:
kubectl create token app-sa -n dev --duration=10m
```

**⚠️ Exam tips:** If a task says "the pod should not be able to reach the API server," set `automountServiceAccountToken: false` on the pod. Verify by `kubectl exec`-ing and checking `/var/run/secrets/kubernetes.io/serviceaccount/` is absent.

---

## Restrict API Server Access (apiserver flags)

**Why it matters:** The API server is the cluster's front door. Insecure flags (anonymous auth, `AlwaysAllow`) are direct findings; this is the highest-risk task because a typo takes the whole control plane down.

**Concepts** — secure values to know:
- `--anonymous-auth=false`
- `--authorization-mode=Node,RBAC` (never `AlwaysAllow`)
- `--enable-admission-plugins=NodeRestriction,PodSecurity,...`
- audit: `--audit-policy-file`, `--audit-log-path` (+ maxage/maxbackup/maxsize)
- TLS/etcd: `--tls-cert-file`, `--tls-private-key-file`, `--etcd-cafile/-certfile/-keyfile`
- `--encryption-provider-config` (secrets at rest)

The apiserver is a **static pod**: edit `/etc/kubernetes/manifests/kube-apiserver.yaml`; kubelet auto-restarts it.

**Commands & examples**

```bash
# 1. BACK UP FIRST — always.
sudo cp /etc/kubernetes/manifests/kube-apiserver.yaml /tmp/kube-apiserver.yaml.bak

# 2. Edit the manifest (add/replace flags under spec.containers[0].command)
sudo vi /etc/kubernetes/manifests/kube-apiserver.yaml

# 3. Watch it restart (takes 30–90s). Don't sit and wait — move to another task.
sudo crictl ps | grep kube-apiserver
kubectl get --raw='/readyz'

# 4. If it does NOT come back, diagnose:
sudo crictl logs $(sudo crictl ps -a | grep kube-apiserver | awk '{print $1}')
sudo journalctl -u kubelet -f
```
```yaml
# Any file-backed flag needs a matching volume + volumeMount, e.g. audit:
    - --audit-policy-file=/etc/kubernetes/audit/policy.yaml
    - --audit-log-path=/var/log/kubernetes/audit.log
...
    volumeMounts:
    - {name: audit-policy, mountPath: /etc/kubernetes/audit, readOnly: true}
    - {name: audit-logs,   mountPath: /var/log/kubernetes}
  volumes:
  - {name: audit-policy, hostPath: {path: /etc/kubernetes/audit, type: DirectoryOrCreate}}
  - {name: audit-logs,   hostPath: {path: /var/log/kubernetes, type: DirectoryOrCreate}}
```

**⚠️ Exam tips:** Forgetting the `volumes`/`volumeMounts` for a file-backed flag is the #1 way to break the apiserver. After editing, the API may be briefly unreachable — that's normal; verify with `/readyz`. Keep the backup so you can restore instantly.

---

## NodeRestriction & Keeping Current

**Why it matters:** NodeRestriction stops a compromised kubelet from editing other nodes/pods; running a current version closes known CVEs — both are explicit hardening competencies.

**Concepts**
- `NodeRestriction` admission plugin limits each kubelet to modifying only its own Node object and pods bound to it.
- Upgrades use `kubeadm upgrade`; drain workloads first, uncordon after.
- CSRs: cluster identities are issued via CertificateSigningRequests you approve/deny.

**Commands & examples**

```bash
# Enable NodeRestriction (apiserver flag):
#   --enable-admission-plugins=NodeRestriction,PodSecurity

# Upgrade flow (control plane):
sudo kubeadm upgrade plan
sudo kubeadm upgrade apply v1.34.x
kubectl drain <node> --ignore-daemonsets --delete-emptydir-data
#   ... upgrade kubelet/kubectl on the node ...
kubectl uncordon <node>

# CSR handling:
kubectl get csr
kubectl certificate approve <csr-name>
kubectl certificate deny  <csr-name>
```

**⚠️ Exam tips:** `kubeadm upgrade plan` is safe to run for inspection. For a CSR task, read whether you should approve or deny — denying a suspicious request is a valid (and tested) answer.

---

## Quick command reference

```bash
kubectl create role NAME --verb=get,list --resource=pods -n NS
kubectl create rolebinding NAME --role=R --serviceaccount=NS:SA -n NS
kubectl auth can-i VERB RES --as=system:serviceaccount:NS:SA -n NS
kubectl auth can-i --list --as=system:serviceaccount:NS:SA -n NS
kubectl patch sa SA -n NS -p '{"automountServiceAccountToken":false}'
kubectl create token SA -n NS --duration=10m
sudo cp /etc/kubernetes/manifests/kube-apiserver.yaml /tmp/kas.bak   # ALWAYS
sudo crictl ps | grep apiserver ; kubectl get --raw=/readyz
kubectl get csr ; kubectl certificate approve|deny NAME
```

## Docs to bookmark

- [Using RBAC Authorization](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
- [RBAC Good Practices](https://kubernetes.io/docs/concepts/security/rbac-good-practices/)
- [Configure ServiceAccounts](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/)
- [Controlling Access to the Kubernetes API](https://kubernetes.io/docs/concepts/security/controlling-access/)
- [Admission Controllers (NodeRestriction)](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/)
- [Certificate Signing Requests](https://kubernetes.io/docs/reference/access-authn-authz/certificate-signing-requests/)
- [Upgrading kubeadm clusters](https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/)
