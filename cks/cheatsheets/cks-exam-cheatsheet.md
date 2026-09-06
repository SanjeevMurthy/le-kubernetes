# CKS Exam Cheatsheet

One page for the morning of the exam. Everything here is already in the notes; this is the compressed form.

<!-- toc -->
## Table of Contents

- [Shell setup, per task host](#shell-setup-per-task-host)
- [Paths](#paths)
- [Commands with no documentation in the exam](#commands-with-no-documentation-in-the-exam)
- [Verification, one line per task family](#verification-one-line-per-task-family)
- [When the API server does not come back](#when-the-api-server-does-not-come-back)
- [YAML shapes worth having in muscle memory](#yaml-shapes-worth-having-in-muscle-memory)
- [Documentation you may open](#documentation-you-may-open)
- [Keys](#keys)
- [Time plan](#time-plan)
- [The eight that fail people](#the-eight-that-fail-people)

<!-- toc stop -->

## Shell setup, per task host

```bash
ssh <nodename>                 # the host the task infobox names
sudo -i                        # root; without it crictl, strace and ss look broken
hostname                       # confirm where you are
k config current-context       # run the context line the task gives you

# only when the task edits a static pod manifest:
cp /etc/kubernetes/manifests/kube-apiserver.yaml /root/kube-apiserver.yaml.bak

# worth one line for YAML-heavy tasks:
printf 'set nu sw=2 et ts=2 ai\n' >> ~/.vimrc
```

`k` and its completion already exist. Do not build aliases; every task is a different host.

## Paths

| Path | What |
|---|---|
| `/etc/kubernetes/manifests/kube-apiserver.yaml` | API server static pod, and `etcd.yaml` beside it |
| `/var/lib/kubelet/config.yaml` | kubelet config, then `systemctl restart kubelet` |
| `/var/lib/kubelet/seccomp/profiles/` | seccomp profiles; pod writes `profiles/<file>.json` |
| `/etc/apparmor.d/` | AppArmor profiles |
| `/etc/falco/falco_rules.yaml` | shipped Falco rules, never edit |
| `/etc/falco/falco_rules.local.yaml` | your Falco overrides, loads last |
| `/etc/falco/falco.yaml` | Falco config, where file output is enabled |
| `/etc/kubernetes/audit/policy.yaml` | audit policy |
| `/etc/kubernetes/pki/etcd/{ca.crt,server.crt,server.key}` | the three etcdctl flags |
| `/etc/kubernetes/admission-controllers/` | ImagePolicyWebhook config and kubeconfig |
| `/var/log/pods/kube-system_kube-apiserver-*/` | logs of a static pod that died |
| `/opt/course/<n>/` | where deliverables are written |

## Commands with no documentation in the exam

Trivy, kube-bench, kubesec, kube-linter and AppArmor documentation are all blocked. These have to come from memory, with `--help` and `man` as the only fallback.

```bash
# kube-bench
kube-bench run --targets master,node
kube-bench run --targets node --check 4.2.1,4.2.4

# trivy
trivy image --severity HIGH,CRITICAL --ignore-unfixed nginx:1.18.0
trivy image --severity CRITICAL -f json -o /opt/course/13/report.json nginx:1.18.0

# kubesec and kube-linter
kubesec scan pod.yaml            # score at .[0].score, read with yq -p json
kube-linter lint deploy.yaml

# AppArmor
apparmor_parser -q /etc/apparmor.d/<file>     # load
apparmor_parser -N /etc/apparmor.d/<file>     # print the profile NAME inside the file
aa-status | grep <profile-name>

# etcd (etcd.io IS allowed, but memorise the flags anyway)
ETCDCTL_API=3 etcdctl \
  --cacert /etc/kubernetes/pki/etcd/ca.crt \
  --cert /etc/kubernetes/pki/etcd/server.crt \
  --key /etc/kubernetes/pki/etcd/server.key \
  get /registry/secrets/<ns>/<name>

# container runtime, because there is no Docker CLI
crictl ps -a
crictl logs <container-id>
crictl inspect --output go-template --template '{{.info.pid}}' <container-id>

# no jq exists
kubectl get X -o jsonpath='{...}'
yq -p json '.field' file.json

# binaries
echo "<hash>  <file>" | sha512sum --check    # exactly two spaces
```

## Verification, one line per task family

```bash
# RBAC, including a case that must say no
k auth can-i list pods --as=system:serviceaccount:<ns>:<sa> -n <ns>

# NetworkPolicy: reachability and DNS
k run probe --rm -it --image=busybox:1.36 -n <ns> -- wget -T3 -qO- <svc>:<port>
k run dns --rm -it --image=busybox:1.36 -n <ns> -- nslookup kubernetes.default

# Pod Security Admission: the violation must be rejected
k run bad --image=nginx --privileged -n <ns>

# AppArmor and seccomp: the blocked action must fail
aa-status | grep <profile>
k exec -n <ns> <pod> -- touch /tmp/x

# gVisor
k exec -n <ns> <pod> -- dmesg | head -3

# encryption at rest
etcdctl ... get /registry/secrets/<ns>/<name> | head -c 200   # expect k8s:enc:aescbc:v1:

# audit: the log must grow
wc -l /var/log/kubernetes/audit/audit.log; k get secrets -A >/dev/null; wc -l /var/log/kubernetes/audit/audit.log

# Falco: the alert must appear in the required format
journalctl -u falco-modern-bpf -u falco --since '-2 min' | tail

# Ingress TLS
curl -kv --resolve <host>:443:<ingress-ip> https://<host>

# immutability
k exec -n <ns> <pod> -- touch /x    # must fail while the pod stays Running

# API server health after any manifest edit
curl -k https://127.0.0.1:6443/readyz
```

## When the API server does not come back

The kubelet rescans `/etc/kubernetes/manifests` about every 20 seconds. **Wait a full minute before re-editing.**

```bash
crictl ps -a | grep apiserver                     # is it trying?
crictl logs <id> 2>&1 | tail -30                  # why did it stop?
journalctl -u kubelet --since '-3 min' | grep -iE 'apiserver|manifest|yaml'
ls -t /var/log/pods/kube-system_kube-apiserver-*/kube-apiserver/ | head -1
cp /root/kube-apiserver.yaml.bak /etc/kubernetes/manifests/kube-apiserver.yaml
```

The four real causes: a misspelled flag, a `volumeMounts` entry with no matching `volumes` entry, YAML indentation, and a webhook kubeconfig missing its `server:` line.

## YAML shapes worth having in muscle memory

```yaml
# default deny both directions
spec: {podSelector: {}, policyTypes: [Ingress, Egress]}

# allow DNS out
egress:
- ports: [{port: 53, protocol: UDP}, {port: 53, protocol: TCP}]

# block only the metadata endpoint
egress:
- to: [{ipBlock: {cidr: 0.0.0.0/0, except: [169.254.169.254/32]}}]

# AppArmor, 1.30 and later, per container
securityContext:
  appArmorProfile: {type: Localhost, localhostProfile: <profile-name>}

# seccomp
securityContext:
  seccompProfile: {type: Localhost, localhostProfile: profiles/audit.json}

# the restricted five
securityContext:
  runAsNonRoot: true
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
  capabilities: {drop: ["ALL"]}
  seccompProfile: {type: RuntimeDefault}

# Pod Security Admission
metadata:
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/enforce-version: latest
```

## Documentation you may open

kubernetes.io/docs and /blog · falco.org/docs · kubernetes-sigs.github.io/bom/cli-reference · etcd.io/docs · the ingress-nginx user guide · docs.cilium.io · istio.io/latest/docs. Nothing else, and no GitHub or external search results.

Page titles to search on kubernetes.io: Auditing · Encrypting Confidential Data at Rest · Restrict a Container's Access to Resources with AppArmor · Restrict a Container's Syscalls with seccomp · Enforce Pod Security Standards with Namespace Labels · Network Policies · Using RBAC Authorization · Admission Controllers Reference · Runtime Class · Certificate Signing Requests · Upgrading kubeadm clusters.

Faster than any of them: `kubectl explain pod.spec.securityContext --recursive`.

## Keys

`Ctrl+Shift+C` and `Ctrl+Shift+V` in the terminal. `Ctrl+C` and `Ctrl+V` elsewhere. `Ctrl+Alt+W` not `Ctrl+W`. Press `i` in vim because INSERT is disabled. `Ctrl+Alt+K` finds the cursor.

## Time plan

16 tasks, 120 minutes, 67 percent to pass, so about 11 tasks right.

| Minute | What |
|---|---|
| 0 to 3 | Read the ReadMe. Skim every task. Note confidence and host. Decide the order. |
| 3 to 105 | Work the order. Roughly 6 to 8 minutes a task. Flag anything past 10 and move. |
| 105 to 120 | Verify everything. Return to flagged tasks for partial credit. Confirm every deliverable file exists. |

Leave the cluster upgrade, ImagePolicyWebhook and the audit policy until after the quick wins. Attempt every task; partial credit counts.

## The eight that fail people

1. An hour on three questions. 2. The wrong host. 3. Not restarting the kubelet. 4. Deleting the wrong resource with no backup. 5. Skipping Falco in preparation. 6. Assuming `jq` exists. 7. Reaching for documentation that is blocked. 8. Not verifying.
