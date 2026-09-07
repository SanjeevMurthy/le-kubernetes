# CKS Cluster Setup (15%)

Cluster Setup is 15 percent of the CKS exam. The exam environment runs Kubernetes v1.35, so every manifest below uses APIs that are GA there. The published curriculum document is still labelled v1.34; nothing in this domain depends on the difference.

Graders score the end state, not the method. Every recipe ends with a command that proves the end state, because a hardening change that silently broke DNS or the API server scores zero.

<!-- toc -->
## Table of Contents

- [What the exam asks](#what-the-exam-asks)
- [Recipe 1: Default-deny ingress and egress without breaking DNS](#recipe-1-default-deny-ingress-and-egress-without-breaking-dns)
- [Recipe 2: Selective allow with podSelector, namespaceSelector and ipBlock](#recipe-2-selective-allow-with-podselector-namespaceselector-and-ipblock)
- [Recipe 3: Block the cloud metadata endpoint](#recipe-3-block-the-cloud-metadata-endpoint)
- [Recipe 4: Fix kube-bench CIS findings on the control plane and kubelet](#recipe-4-fix-kube-bench-cis-findings-on-the-control-plane-and-kubelet)
- [Recipe 5: Restrict TLS versions and ciphers on the API server and etcd](#recipe-5-restrict-tls-versions-and-ciphers-on-the-api-server-and-etcd)
- [Recipe 6: Serve an Ingress over TLS and force the redirect](#recipe-6-serve-an-ingress-over-tls-and-force-the-redirect)
- [Recipe 7: Verify platform binaries with sha512sum](#recipe-7-verify-platform-binaries-with-sha512sum)
- [Recipe 8: Reduce Dashboard and GUI exposure](#recipe-8-reduce-dashboard-and-gui-exposure)
- [Quick reference](#quick-reference)
- [Memorise](#memorise)

<!-- toc stop -->

## What the exam asks

| Task type | Sources | Drill |
|---|---|---|
| NetworkPolicy: default deny, selectors, DNS egress | 12 | Q1 |
| kube-bench and CIS remediation | 12 | Q2, Q22 |
| API server and etcd flags, including TLS protocol and ciphers | 9 | Q33 |
| Ingress with a TLS secret | 7 | Q3 |
| Binary verification with sha512sum | 7 | Killercoda "Verify Platform Binaries" |
| Kubelet config hardening (CIS 4.2.x) | 5 | Q2, Q22 |
| Node metadata endpoint protection | 4 | Q24 |
| Kubernetes Dashboard hardening | 2 | none |

Sources are distinct candidate reports counted in the exam research report, section 3. NetworkPolicy and kube-bench sit in the top tier reported by 10 or more sources, so plan on meeting at least one of each. Every task host has `kubectl` with a `k` alias, `yq`, `curl`, `wget` and `man`. There is no `jq`, so no command in this note uses it.

## Recipe 1: Default-deny ingress and egress without breaking DNS

**Goal.** A namespace where no pod sends or receives traffic except DNS lookups to CoreDNS, with `nslookup` still succeeding from inside the namespace.

**Frequency.** 12 candidate sources (research section 3 row 6; `../practice-tests/exam-questions/cks-real-exam-questions.md`). Drill: Q1.

**Commands.**
```bash
# Apply the DNS allow policy FIRST. Applying deny-all first breaks resolution for
# everything already running while you type the second policy.
kubectl apply -f - <<'EOF'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns-egress
  namespace: prod
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: kube-system
      podSelector:
        matchLabels:
          k8s-app: kube-dns
    ports:
    - port: 53
      protocol: UDP
    - port: 53
      protocol: TCP
EOF

kubectl apply -f - <<'EOF'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: prod
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
EOF
```
**Verify.**
```bash
kubectl get netpol default-deny-all -n prod -o jsonpath='{.spec.podSelector}|{.spec.policyTypes[*]}{"\n"}'   # expect {}|Ingress Egress

# Effect test. This is the check that catches the DNS trap.
kubectl run dnstest -n prod --rm -i --restart=Never --image=busybox:1.36 \
  --pod-running-timeout=90s -- nslookup kubernetes.default.svc.cluster.local
```
**Gotchas.**
- A policy with `policyTypes` but no matching rule block denies that whole direction. That is the mechanism, not a bug.
- Port 53 needs two entries, one `UDP` and one `TCP`. `protocol` defaults to TCP, so a single entry leaves normal queries blocked and the pod hangs instead of erroring.
- `namespaceSelector` and `podSelector` written as one list item are an AND, which is what this rule wants: the kube-system namespace and the kube-dns pods.
- `kubernetes.io/metadata.name` is set automatically on every namespace, so never invent a custom label for the kube-system selector.
- Policies are namespace scoped and purely additive. There is no deny rule and no global policy.

**Docs.** kubernetes.io "Network Policies", the "Default deny all ingress and all egress traffic" example near the bottom of the page. docs.cilium.io "Network Policy" when the CNI is Cilium.

## Recipe 2: Selective allow with podSelector, namespaceSelector and ipBlock

**Goal.** One backend workload reachable only from named sources on one port, with everything else still denied by the default-deny policy.

**Frequency.** 12 candidate sources (research section 3 row 6). Drill: Q1.

**Commands.**
```bash
# OR across list items: from app=frontend pods in this namespace, OR any pod in
# the monitoring namespace, OR the 10.0.0.0/8 range minus 10.0.5.0/24.
kubectl apply -f - <<'EOF'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend
  namespace: prod
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: monitoring
    - ipBlock:
        cidr: 10.0.0.0/8
        except:
        - 10.0.5.0/24
    ports:
    - port: 8080
      protocol: TCP
EOF

# AND inside one list item: only app=frontend pods that live in the monitoring
# namespace. One dash, two selectors under it. Swap this ingress block in.
#  ingress:
#  - from:
#    - namespaceSelector:
#        matchLabels:
#          kubernetes.io/metadata.name: monitoring
#      podSelector:
#        matchLabels:
#          app: frontend
```
**Verify.**
```bash
kubectl get netpol allow-frontend -n prod \
  -o jsonpath='{.spec.ingress[*].from[*].podSelector.matchLabels.app}{"\n"}'
kubectl get netpol allow-frontend -n prod -o jsonpath='{.spec.ingress[*].ports[*].port}{"\n"}'

kubectl run probe-ok -n prod --rm -i --restart=Never --labels=app=frontend \
  --image=busybox:1.36 -- wget -qO- --timeout=5 backend:8080
kubectl run probe-deny -n prod --rm -i --restart=Never --labels=app=other \
  --image=busybox:1.36 -- wget -qO- --timeout=5 backend:8080
```
**Gotchas.**
- The dash placement is the whole answer. Two dashes under `from` means OR, one dash with two selectors indented under it means AND.
- `ports` sits beside `from` inside the same rule, not inside a `from` item. Wrong indentation there opens every port.
- `ipBlock` matches the source address the CNI sees, so SNATed traffic will not match the pod CIDR you expect. Prefer selectors for in-cluster traffic.
- Adding an ingress allow does not help if the client namespace has its own default-deny egress.
- Back a policy up with `kubectl get netpol <name> -n prod -o yaml > /tmp/bak.yaml` before editing it.

**Docs.** kubernetes.io "Network Policies", section "Behavior of `to` and `from` selectors".

## Recipe 3: Block the cloud metadata endpoint

**Goal.** No pod in the namespace reaches 169.254.169.254, while all other egress keeps working.

**Frequency.** 4 candidate sources (research section 3 row 24). Drill: Q24.

**Commands.**
```bash
kubectl apply -f - <<'EOF'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-metadata-access
  namespace: prod
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  - to:
    - ipBlock:
        cidr: 0.0.0.0/0
        except:
        - 169.254.169.254/32
EOF
```
**Verify.**
```bash
kubectl get netpol deny-metadata-access -n prod \
  -o jsonpath='{.spec.egress[*].to[*].ipBlock.except[*]}{"\n"}'   # expect 169.254.169.254/32

kubectl run metatest -n prod --rm -i --restart=Never --image=busybox:1.36 \
  -- wget -qO- --timeout=5 http://169.254.169.254/latest/meta-data/
# expect: wget: download timed out
```
**Gotchas.**
- NetworkPolicy has no deny rule. The only way to block one address is to allow a wide CIDR and carve the address out with `except`.
- Every `except` entry must sit inside the `cidr` it belongs to. `169.254.169.254/32` under `0.0.0.0/0` is valid; under `10.0.0.0/8` it is rejected.
- This policy allows all other egress, so for the pods it selects it cancels a default-deny egress in the same namespace. Keep the selector narrow and re-add the DNS rule from Recipe 1 when both are wanted.
- Some labs use a different metadata address such as `192.168.100.21`. Read the task rather than typing the AWS address from memory.

**Docs.** kubernetes.io "Network Policies" for `ipBlock`, and "Securing a Cluster" for the metadata note.

## Recipe 4: Fix kube-bench CIS findings on the control plane and kubelet

**Goal.** The named CIS checks move from FAIL to PASS and the control plane still serves requests.

**Frequency.** 12 candidate sources (research section 3 row 4), plus 5 for kubelet config alone (row 30). Drill: Q2, Q22.

**Commands.**
```bash
sudo -i
cp /etc/kubernetes/manifests/kube-apiserver.yaml /root/kube-apiserver.yaml.bak

kube-bench run --targets master,node 2>&1 | tee /tmp/bench.txt
grep '^\[FAIL\]' /tmp/bench.txt
kube-bench run --targets master --check 1.2.9

# 1.2.x: API server manifest, under spec.containers[0].command
vi /etc/kubernetes/manifests/kube-apiserver.yaml
#   - --anonymous-auth=false
#   - --authorization-mode=Node,RBAC
#   - --profiling=false

# 1.3.x and 1.4.x: controller manager and scheduler manifests
vi /etc/kubernetes/manifests/kube-controller-manager.yaml
#   - --profiling=false

# 1.1.x and 2.x: etcd data directory and manifest permissions
chown -R etcd:etcd /var/lib/etcd
chmod 700 /var/lib/etcd
chmod 600 /etc/kubernetes/manifests/etcd.yaml

# 4.2.x: kubelet config file, YAML not flags
vi /var/lib/kubelet/config.yaml
#   readOnlyPort: 0
#   protectKernelDefaults: true
#   authentication:
#     anonymous:
#       enabled: false
#   authorization:
#     mode: Webhook
systemctl restart kubelet
```
**Verify.**
```bash
crictl ps | grep -E 'kube-apiserver|etcd'
systemctl is-active kubelet
kubectl get --raw='/readyz?verbose' | tail -3

kube-bench run --targets master --check 1.2.9
kube-bench run --targets node --check 4.2.1,4.2.2   # every line must start with [PASS]
```
**Gotchas.**
- Saving a static manifest restarts that control plane pod. The kubelet rescans `/etc/kubernetes/manifests` about every 20 seconds, so wait and watch rather than editing again.
- If `kubectl` starts hanging the API server did not come back. Read `journalctl -fu kubelet | grep -i apiserver`, then `crictl ps -a | grep apiserver` and `crictl logs <id>`, then the newest file under `/var/log/pods/kube-system_kube-apiserver-*/`.
- Kubelet findings live in `/var/lib/kubelet/config.yaml`, which is YAML. Do not add a `--flag` there.
- `protectKernelDefaults: true` makes the kubelet refuse to start when node sysctls do not match, so check `systemctl is-active kubelet` straight after the restart.
- kube-bench prints the exact remediation text for each FAIL, naming the file and the setting. Read it instead of guessing, and fix only the checks the task lists.

**Docs.** kube-bench documentation is not on the allowed list, so its flags must be memorised; in the exam use `kube-bench --help` and `kube-bench run --help` plus the remediation text kube-bench prints. For the settings being changed, kubernetes.io "kube-apiserver" and "kubelet" command line tool references are allowed, as is `man kubelet`.

## Recipe 5: Restrict TLS versions and ciphers on the API server and etcd

**Goal.** The API server and etcd refuse older TLS handshakes and offer only the named cipher suites.

**Frequency.** 9 candidate sources (research section 3 row 9). Drill: Q33.

**Commands.**
```bash
sudo -i
cp /etc/kubernetes/manifests/kube-apiserver.yaml /root/kube-apiserver.yaml.bak
cp /etc/kubernetes/manifests/etcd.yaml /root/etcd.yaml.bak

vi /etc/kubernetes/manifests/kube-apiserver.yaml
#   - --tls-min-version=VersionTLS13
#   - --tls-cipher-suites=TLS_AES_128_GCM_SHA256,TLS_AES_256_GCM_SHA384

vi /etc/kubernetes/manifests/etcd.yaml
#   - --cipher-suites=TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384
```
**Verify.**
```bash
# The old protocol must fail the handshake.
openssl s_client -connect 127.0.0.1:6443 -tls1_2 </dev/null 2>&1 \
  | grep -E 'alert|handshake failure|Protocol'

# The new one must succeed and name the negotiated suite.
openssl s_client -connect 127.0.0.1:6443 -tls1_3 </dev/null 2>&1 | grep -E 'Protocol|Cipher'

# etcd needs client certificates to complete the handshake.
openssl s_client -connect 127.0.0.1:2379 \
  -CAfile /etc/kubernetes/pki/etcd/ca.crt \
  -cert /etc/kubernetes/pki/etcd/server.crt \
  -key /etc/kubernetes/pki/etcd/server.key </dev/null 2>&1 | grep -E 'Protocol|Cipher'

crictl ps | grep -E 'kube-apiserver|etcd'
```
**Gotchas.**
- The value is `VersionTLS13`, not `TLSv1.3` and not `1.3`. A wrong spelling stops the API server from starting at all.
- TLS 1.3 accepts only TLS 1.3 suite names, so `TLS_ECDHE_...` names alongside `--tls-min-version=VersionTLS13` are a configuration error.
- The etcd flag is `--cipher-suites`, not `--tls-cipher-suites`. The two components spell it differently.
- etcd is a static pod too, and breaking it takes the whole control plane down. Copy the backup before the first keystroke.
- `openssl s_client` against 6443 without a client certificate still completes enough of the handshake to print the protocol and cipher lines.

**Docs.** kubernetes.io "kube-apiserver" command line tool reference for `--tls-min-version` and `--tls-cipher-suites`. etcd.io/docs for `--cipher-suites`. Both domains are allowed.

## Recipe 6: Serve an Ingress over TLS and force the redirect

**Goal.** `https://web.example` serves the app through ingress-nginx using a `kubernetes.io/tls` secret, and plain HTTP redirects to it.

**Frequency.** 7 candidate sources (research section 3 row 14). Drill: Q3.

**Commands.**
```bash
openssl req -x509 -newkey rsa:2048 -nodes -keyout tls.key -out tls.crt \
  -subj "/CN=web.example" -days 365

kubectl create secret tls web-tls --cert=tls.crt --key=tls.key -n prod

kubectl apply -f - <<'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web
  namespace: prod
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - web.example
    secretName: web-tls
  rules:
  - host: web.example
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web
            port:
              number: 80
EOF
```
**Verify.**
```bash
kubectl get secret web-tls -n prod -o jsonpath='{.type}{"\n"}'   # kubernetes.io/tls
kubectl get ingress web -n prod -o jsonpath='{.spec.tls[*].hosts[*]}|{.spec.tls[*].secretName}{"\n"}'

IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.spec.clusterIP}')
curl -kv --resolve web.example:443:"$IP" https://web.example 2>&1 | grep -E 'subject:|HTTP/'
curl -sI --resolve web.example:80:"$IP" http://web.example | head -1
# expect: HTTP/1.1 308 Permanent Redirect
```
**Gotchas.**
- The secret must live in the same namespace as the Ingress. A secret in `default` referenced from `prod` fails silently and the controller serves its own fake certificate.
- `spec.tls[].hosts` must contain the hostname used in `spec.rules[].host`. A mismatch also falls back to the fake certificate, visible as "Kubernetes Ingress Controller Fake Certificate" in the `curl -kv` subject line.
- The annotation value is the quoted string `"true"`. Unquoted `true` is a boolean and the manifest is rejected.
- `-nodes` is what leaves the key unencrypted. Without it openssl prompts for a passphrase and the resulting secret does not work.
- `ingressClassName` is required when the cluster has more than one controller, otherwise the Ingress never gets an address.

**Docs.** kubernetes.io "Ingress", section "TLS". The ingress-nginx user guide is allowed for annotation names.

## Recipe 7: Verify platform binaries with sha512sum

**Goal.** Each supplied binary is compared against its published hash, and mismatches are reported or deleted as the task instructs.

**Frequency.** 7 candidate sources (research section 3 row 13). Drill: Killercoda "Verify Platform Binaries" (no repo question yet).

**Commands.**
```bash
sha512sum /opt/binaries/kubelet

# Published checksum for the exam version.
curl -sL https://dl.k8s.io/release/v1.35.0/bin/linux/amd64/kubelet.sha512

# Compare in one step. --check wants "<hash><two spaces><file>".
echo "$(curl -sL https://dl.k8s.io/release/v1.35.0/bin/linux/amd64/kubelet.sha512)  /opt/binaries/kubelet" \
  | sha512sum --check

# Compare the binary actually running on the node.
sha512sum "$(command -v kubelet)"

# When a file of "<hash>  <name>" lines is supplied, check them all at once.
cd /opt/binaries && sha512sum --check /opt/binaries/expected.sha512
```
**Verify.**
```bash
echo "$(cat /opt/binaries/kubelet.sha512)  /opt/binaries/kubelet" | sha512sum --check
# expect: /opt/binaries/kubelet: OK

echo "$(cat /opt/binaries/kubelet.sha512)  /opt/binaries/kubelet" \
  | sha512sum --check --status; echo "exit=$?"   # 0 match, 1 tampered
```
**Gotchas.**
- Two spaces between the hash and the filename. One space makes `sha512sum --check` report "no properly formatted checksum lines found" instead of a mismatch.
- The exam asks for sha512 far more often than sha256, so read the extension you were given.
- The published `.sha512` file holds only the hash with no filename, which is why the `echo` wrapper is needed before piping into `--check`.
- Check the file at the path the task names and, separately, the running binary found with `command -v`. Comparing the wrong pair is the usual mistake.
- Re-read the deliverable: some variants want mismatched files deleted, others want the names written to a file under `/opt/course/`.

**Docs.** kubernetes.io "Install and Set Up kubectl on Linux" shows the same verify pattern and is allowed. `man sha512sum` covers `--check` and `--status`.

## Recipe 8: Reduce Dashboard and GUI exposure

**Goal.** No cluster-admin binding to the Dashboard ServiceAccount, no anonymous login, and no NodePort or LoadBalancer reaching it from outside.

**Frequency.** 2 candidate sources (research section 3 row 28). Drill: none.

The curriculum bullet "Minimize use of, and access to, GUI elements" was removed in October 2024, so this is unlikely on a current exam. Skim it once and spend the time on Recipes 1 to 6. The RBAC mechanics behind it are covered in [02-cluster-hardening.md](02-cluster-hardening.md).

**Commands.**
```bash
kubectl get clusterrolebinding -o wide | grep -i dashboard
kubectl get deploy kubernetes-dashboard -n kubernetes-dashboard -o yaml \
  | grep -E 'enable-skip-login|enable-insecure-login'

kubectl get clusterrolebinding kubernetes-dashboard -o yaml > /tmp/crb.yaml
kubectl delete clusterrolebinding kubernetes-dashboard

kubectl create rolebinding dashboard-view --clusterrole=view \
  --serviceaccount=kubernetes-dashboard:kubernetes-dashboard -n kubernetes-dashboard
kubectl patch svc kubernetes-dashboard -n kubernetes-dashboard \
  -p '{"spec":{"type":"ClusterIP"}}'
```
**Verify.**
```bash
kubectl auth can-i list secrets \
  --as=system:serviceaccount:kubernetes-dashboard:kubernetes-dashboard -n default   # expect no
kubectl get svc kubernetes-dashboard -n kubernetes-dashboard \
  -o jsonpath='{.spec.type}{"\n"}'   # expect ClusterIP
```
**Gotchas.**
- Deleting a ClusterRoleBinding is immediate and cannot be undone, so save the YAML first.
- `--enable-skip-login` is an argument on the Dashboard deployment, so removing it restarts the pod.
- The `view` ClusterRole still reads ConfigMaps. If the task forbids secret access, prove it with `kubectl auth can-i` rather than assuming.

**Docs.** kubernetes.io "Deploy and Access the Kubernetes Dashboard" and "Using RBAC Authorization".

## Quick reference

```bash
# NetworkPolicy
kubectl get netpol <n> -n prod -o jsonpath='{.spec.podSelector}|{.spec.policyTypes[*]}{"\n"}'
kubectl run t -n prod --rm -i --restart=Never --image=busybox:1.36 -- nslookup kubernetes.default

# kube-bench
kube-bench run --targets master,node 2>&1 | tee /tmp/bench.txt
grep '^\[FAIL\]' /tmp/bench.txt
kube-bench run --targets master --check 1.2.9
kube-bench run --targets node --check 4.2.1,4.2.2

# Control plane health after an edit
crictl ps | grep -E 'kube-apiserver|etcd'
journalctl -fu kubelet | grep -i apiserver
ls -t /var/log/pods/kube-system_kube-apiserver-*/kube-apiserver/ | head -1
kubectl get --raw='/readyz?verbose' | tail -3

# TLS on the API server
openssl s_client -connect 127.0.0.1:6443 -tls1_2 </dev/null 2>&1 | grep -E 'Protocol|alert'

# Ingress TLS
openssl req -x509 -newkey rsa:2048 -nodes -keyout tls.key -out tls.crt -subj "/CN=web.example" -days 365
kubectl create secret tls web-tls --cert=tls.crt --key=tls.key -n prod
curl -kv --resolve web.example:443:"$IP" https://web.example

# Binaries
sha512sum /opt/binaries/kubelet
echo "<hash>  /opt/binaries/kubelet" | sha512sum --check
sha512sum "$(command -v kubelet)"
```

CIS check id to the file you edit:

| CIS id range | Component | File to edit | Applied by |
|---|---|---|---|
| 1.1.x | Manifest and PKI permissions | `/etc/kubernetes/manifests/`, `/etc/kubernetes/pki/` | `chmod`, `chown`, immediate |
| 1.2.x | API server | `/etc/kubernetes/manifests/kube-apiserver.yaml` | kubelet restarts the static pod |
| 1.3.x | Controller manager | `/etc/kubernetes/manifests/kube-controller-manager.yaml` | kubelet restarts the static pod |
| 1.4.x | Scheduler | `/etc/kubernetes/manifests/kube-scheduler.yaml` | kubelet restarts the static pod |
| 2.x | etcd | `/etc/kubernetes/manifests/etcd.yaml`, `/var/lib/etcd` | kubelet restarts the static pod |
| 4.1.x | Kubelet service files | `/etc/systemd/system/kubelet.service.d/` | `systemctl daemon-reload`, restart |
| 4.2.x | Kubelet configuration | `/var/lib/kubelet/config.yaml` | `systemctl restart kubelet` |
| 5.x | Policies (RBAC, PSA, network) | cluster objects | `kubectl apply` |

## Memorise

- Write the DNS allow policy before the default deny, and give port 53 both a UDP and a TCP entry.
- Empty `podSelector: {}` selects every pod in the namespace; `policyTypes` without a matching rule block denies that direction outright.
- Two dashes under `from` is OR. One dash with `namespaceSelector` and `podSelector` indented under it is AND.
- Blocking one address means `ipBlock: {cidr: 0.0.0.0/0, except: [169.254.169.254/32]}`. NetworkPolicy has no deny rule.
- `cp /etc/kubernetes/manifests/kube-apiserver.yaml /root/kube-apiserver.yaml.bak` before touching any static manifest, every time.
- CIS 1.2.x is the API server manifest, 1.3.x controller manager, 2.x etcd, 4.2.x `/var/lib/kubelet/config.yaml` followed by `systemctl restart kubelet`.
- The four kubelet fixes: `readOnlyPort: 0`, `authentication.anonymous.enabled: false`, `authorization.mode: Webhook`, `protectKernelDefaults: true`.
- `--tls-min-version=VersionTLS13` and `--tls-cipher-suites=...` on the API server; `--cipher-suites=...` on etcd.
- `openssl req -x509 -newkey rsa:2048 -nodes -keyout tls.key -out tls.crt -subj "/CN=web.example" -days 365`.
- `kubectl create secret tls <name> --cert=tls.crt --key=tls.key -n <ns>` produces type `kubernetes.io/tls`, and the secret shares the Ingress namespace.
- `nginx.ingress.kubernetes.io/ssl-redirect: "true"`, with the quotes.
- `echo "<hash>  <file>" | sha512sum --check` needs exactly two spaces.
- kube-bench, Trivy, AppArmor and kubesec documentation are not allowed. Their flags are memory only; on the host fall back to `--help` and `man`.
- Allowed in-exam documentation: kubernetes.io/docs, kubernetes.io/blog, falco.org/docs, kubernetes-sigs.github.io/bom, etcd.io/docs, the ingress-nginx user guide, docs.cilium.io and istio.io/latest/docs.
