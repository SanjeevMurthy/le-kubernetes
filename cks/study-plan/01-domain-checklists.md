# CKS Domain Checklists

Your mastery tracker, and the coverage map for the whole kit. Every line is a competency drawn from the official CKS curriculum (document v1.34), paired with the note recipe that teaches it and the practice question that drills it.

Mark each line:

- `[ ]` not started
- `[~]` understood the concept, can do it with the notes open
- `[x]` **can do it timed, under 8 minutes, closed book**

You are ready when nearly every line is `[x]`. Re-score on **8 Nov**, **29 Nov** and **5 Dec**, and after each killer.sh session.

Question ids marked *(planned)* are built in Phase 2 of the kit. Until then, drill the matching Killercoda scenario named in [`02-resources.md`](02-resources.md).

---

<!-- toc -->
## Table of Contents

- [Domain 1 — Cluster Setup (15%)](#domain-1--cluster-setup-15)
- [Domain 2 — Cluster Hardening (15%)](#domain-2--cluster-hardening-15)
- [Domain 3 — System Hardening (10%)](#domain-3--system-hardening-10)
- [Domain 4 — Minimize Microservice Vulnerabilities (20%)](#domain-4--minimize-microservice-vulnerabilities-20)
- [Domain 5 — Supply Chain Security (20%)](#domain-5--supply-chain-security-20)
- [Domain 6 — Monitoring, Logging and Runtime Security (20%)](#domain-6--monitoring-logging-and-runtime-security-20)
- [Tool mastery](#tool-mastery)
- [Paths to recite](#paths-to-recite)
- [Re-score log](#re-score-log)

<!-- toc stop -->

## Domain 1 — Cluster Setup (15%)

> Curriculum bullets: use Network security policies to restrict cluster level access · use CIS benchmark to review the security configuration of Kubernetes components (etcd, kubelet, kubedns, kubeapi) · properly set up Ingress objects with TLS · protect node metadata and endpoints · verify platform binaries before deploying

**Network security policies**

- [ ] Write a default-deny policy for both ingress and egress in a namespace — note 01 recipe 1, Q1
- [ ] Re-allow DNS on UDP and TCP 53 so a default-deny egress does not break name resolution — note 01 recipe 1, Q1
- [ ] Selective allow with `podSelector`, `namespaceSelector`, `ipBlock` and `ports` — note 01 recipe 2, Q1
- [ ] Explain why two entries in a `from` list are OR but two keys in one entry are AND — note 01 recipe 2, Q1
- [ ] Confirm the CNI actually enforces policy before trusting a result — note 01 recipe 2, lab tier 1

**CIS benchmark**

- [ ] Run `kube-bench` against the control plane and a node, and read a FAIL block — note 01 recipe 4, Q2
- [ ] Map a CIS id to the file that fixes it (API server manifest, controller-manager, etcd, kubelet config) — note 01 recipe 4, Q2
- [ ] Remediate kubelet findings in `/var/lib/kubelet/config.yaml` and restart the kubelet — note 01 recipe 4, Q22 *(planned)*
- [ ] Re-run a single check to confirm the fix rather than the whole suite — note 01 recipe 4, Q2
- [ ] Set TLS minimum version and cipher suites on the API server and etcd — note 01 recipe 5, Q33 *(planned)*

**Ingress with TLS**

- [ ] Generate a self-signed certificate and key with one `openssl` command — note 01 recipe 6, Q3
- [ ] Create a `kubernetes.io/tls` Secret and reference it from `spec.tls` — note 01 recipe 6, Q3
- [ ] Force the HTTP to HTTPS redirect and test with `curl -k` — note 01 recipe 6, Q3

**Node metadata and endpoints**

- [ ] Block egress to `169.254.169.254/32` with `ipBlock` and `except` — note 01 recipe 3, Q24 *(planned)*
- [ ] Reduce Dashboard and GUI exposure — note 01 recipe 8

**Platform binaries**

- [ ] Verify a binary against a published `sha512` checksum and act on a mismatch — note 01 recipe 7

---

## Domain 2 — Cluster Hardening (15%)

> Curriculum bullets: use Role Based Access Controls to minimize exposure · exercise caution in using service accounts, e.g. disable defaults, minimize permissions on newly created ones · restrict access to Kubernetes API · upgrade Kubernetes to avoid vulnerabilities

**RBAC**

- [ ] Create Roles, ClusterRoles and their bindings imperatively, under time pressure — note 02 recipe 1, Q4
- [ ] Write the ServiceAccount subject form `system:serviceaccount:<ns>:<name>` from memory — note 02 recipe 1, Q4
- [ ] Verify with `kubectl auth can-i --as`, including the negative cases — note 02 recipe 1, Q4
- [ ] Find and delete bindings that grant `system:anonymous` or `system:unauthenticated` — note 02 recipe 1, Q29 *(planned)*
- [ ] Narrow an over-permissive existing Role rather than replacing it — note 02 recipe 1, Q4

**ServiceAccounts**

- [ ] Disable token automount on the ServiceAccount and on the pod, and know which wins — note 02 recipe 2, Q5
- [ ] Mint a short-lived token with `kubectl create token` — note 02 recipe 2, Q5
- [ ] Prove from inside a pod that no token is mounted — note 02 recipe 2, Q5

**Restrict API access**

- [ ] Edit API server flags safely: back up, edit, watch it restart — note 02 recipe 3, Q6
- [ ] Recover a dead API server using `crictl` and `/var/log/pods` — note 02 recipe 3, Q23 *(planned)*
- [ ] Diagnose a manifest whose volumeMount has no matching volume — note 02 recipe 3, Q37 *(planned)*
- [ ] Enable NodeRestriction and demonstrate what it blocks — note 02 recipe 4, Q6
- [ ] Turn off anonymous auth and set `--authorization-mode=Node,RBAC` — note 02 recipe 3, Q6

**Upgrades and certificates**

- [ ] Upgrade a kubeadm control plane and then a worker, in the right order — note 02 recipe 5, Q39 *(planned)*
- [ ] Issue a user certificate through a CertificateSigningRequest and bind a Role to it — note 02 recipe 6, Q40 *(planned)*
- [ ] Read contexts and decode the client certificate inside a kubeconfig — note 02 recipe 7

---

## Domain 3 — System Hardening (10%)

> Curriculum bullets: minimize host OS footprint (reduce attack surface) · using least-privilege identity and access management · minimize external access to the network · appropriately use kernel hardening tools such as AppArmor, seccomp

**Host OS footprint**

- [ ] Find what is listening with `ss -tlpn` and trace a port to its unit — note 03, Q41 *(planned)*
- [ ] Disable, stop and mask a service, and remove a package — note 03, Q41 *(planned)*
- [ ] Blacklist a kernel module so it cannot be loaded at boot — note 03, Q42 *(planned)*

**Least-privilege identity**

- [ ] Lock an account, change its shell to nologin, remove it from a group — note 03, Q42 *(planned)*
- [ ] Remove a sudoers grant and validate the file with `visudo -c` — note 03, Q42 *(planned)*
- [ ] Harden `sshd_config` and validate with `sshd -t` before restarting — note 03, Q42 *(planned)*

**Minimize external network access**

- [ ] Write host firewall rules that allow only what is needed and survive a reboot — note 03, Q41 *(planned)*

**Kernel hardening**

- [ ] Load an AppArmor profile with `apparmor_parser` and confirm with `aa-status` — note 03, Q7
- [ ] Read the profile **name** from inside the file, which is not the file name — note 03, Q34 *(planned)*
- [ ] Confine a pod with `securityContext.appArmorProfile` (1.30 and later) and with the legacy annotation — note 03, Q7
- [ ] Schedule the pod onto the node where the profile is loaded — note 03, Q7
- [ ] Write a seccomp profile under `/var/lib/kubelet/seccomp/profiles/` and reference it — note 03, Q8
- [ ] Use `RuntimeDefault` and know when `Localhost` is required instead — note 03, Q8
- [ ] Block a specific syscall with `SCMP_ACT_ERRNO` and prove it fails — note 03, Q30 *(planned)*
- [ ] Drop all capabilities and add back only what is needed — note 03, Q15
- [ ] Recite which securityContext fields are pod-level and which are container-level — note 03, Q15
- [ ] Trace a container's syscalls with `crictl inspect` and `strace` — note 03, Q43 *(planned)*

---

## Domain 4 — Minimize Microservice Vulnerabilities (20%)

> Curriculum bullets: use appropriate pod security standards · manage kubernetes secrets · understand and implement isolation techniques (multi-tenancy, sandboxed containers, etc.) · implement Pod-to-Pod encryption (Cilium, Istio)

**Pod Security Standards**

- [ ] Label a namespace for `enforce`, `audit` and `warn`, with a version — note 04, Q9
- [ ] Recite the four fields a pod needs to satisfy `restricted` — note 04, Q9
- [ ] Know that `enforce` blocks new pods only and existing ones keep running — note 04, Q9
- [ ] Find which existing pods violate a standard and write them to a file — note 04, Q36 *(planned)*

**Secrets**

- [ ] Write an `EncryptionConfiguration` with the providers in the right order — note 04, Q10
- [ ] Wire `--encryption-provider-config` with its volume and volumeMount — note 04, Q10
- [ ] Re-encrypt every existing secret after changing the key — note 04, Q26 *(planned)*
- [ ] Read a secret straight from etcd with `etcdctl` and its three certificate flags — note 04, Q25 *(planned)*
- [ ] Confirm encryption by finding the `k8s:enc:aescbc:v1:` prefix in etcd — note 04, Q10

**Isolation**

- [ ] Configure a RuntimeClass with the `runsc` handler and run a pod under it — note 04, Q12
- [ ] Prove a pod is sandboxed by reading `dmesg` inside it — note 04, Q28 *(planned)*
- [ ] Choose the right isolation tool for a stated requirement — note 04 isolation table

**Admission control**

- [ ] Write a Gatekeeper ConstraintTemplate with its Rego, plus a Constraint — note 04, Q11
- [ ] Write a Kyverno ClusterPolicy with `validationFailureAction: Enforce` — note 04, Q11
- [ ] Recognise a ValidatingAdmissionPolicy and its binding — note 04

**Pod-to-pod encryption**

- [ ] Write a CiliumNetworkPolicy including an L7 HTTP rule — note 04, Q35 *(planned)*
- [ ] Enable and verify Cilium transparent encryption — note 04, Q35 *(planned)*
- [ ] Enforce STRICT mTLS in a namespace with an Istio PeerAuthentication — note 04, Q44 *(planned)*

---

## Domain 5 — Supply Chain Security (20%)

> Curriculum bullets: minimize base image footprint · understand your supply chain (e.g. SBOM, CI/CD, artifact repositories) · secure your supply chain (permitted registries, sign and validate artifacts, etc.) · perform static analysis of user workloads and container images (e.g. Kubesec, KubeLinter)

**Base images**

- [ ] Write a multi-stage Dockerfile whose final image is minimal and non-root — note 05, Q27 *(planned)*
- [ ] Spot the security problems in a given Dockerfile and fix only those — note 05, Q27 *(planned)*

**Understand the supply chain**

- [ ] Generate an SBOM with `bom` and read its contents — note 05, Q38 *(planned)*
- [ ] Pin an image by digest rather than by tag — note 05

**Secure the supply chain**

- [ ] Configure ImagePolicyWebhook: admission config, webhook kubeconfig, API server flags, volume — note 05, Q14
- [ ] Fix a webhook kubeconfig that is missing its `server:` line — note 05, Q21 *(planned)*
- [ ] Restrict images to permitted registries with an admission policy — note 05, Q14
- [ ] Verify a signature with `cosign` — note 05

**Static analysis**

- [ ] Scan an image with Trivy for HIGH and CRITICAL findings and act on the result — note 05, Q13
- [ ] List the images running in a namespace and find the vulnerable one — note 05, Q13
- [ ] Score a manifest with `kubesec` and fix what it flags — note 05, Q15
- [ ] Lint a manifest with `kube-linter` — note 05

---

## Domain 6 — Monitoring, Logging and Runtime Security (20%)

> Curriculum bullets: perform behavioral analytics to detect malicious activities · detect threats within physical infrastructure, apps, networks, data, users and workloads · investigate and identify phases of attack and bad actors within the environment · ensure immutability of containers at runtime · use Kubernetes audit logs to monitor access

**Falco** — the most reported task family on the exam

- [ ] Read a shipped rule and understand every field — note 06, Q16
- [ ] Override a shipped rule by re-declaring its name in the local rules file — note 06, Q16
- [ ] Find output field names with `falco --list` — note 06, Q19 *(planned)*
- [ ] Rewrite an `output` line to a required format — note 06, Q19 *(planned)*
- [ ] Reload rules without losing the service, and know which unit name is in use — note 06, Q19 *(planned)*
- [ ] Read alerts from the journal and from the log file — note 06, Q16
- [ ] Map an alert's container id back to its pod with `crictl`, then stop the workload — note 06, Q31 *(planned)*

**Audit logs**

- [ ] Write a policy whose rules are in the right order, knowing first match wins — note 06, Q17
- [ ] Use all four levels correctly and set `omitStages` — note 06, Q17
- [ ] Add the five `--audit-log-*` flags and both hostPath volumes with the right types — note 06, Q17
- [ ] Confirm the log is actually growing after the API server restarts — note 06, Q17
- [ ] Mine an audit log without `jq`: who deleted a secret, from which IP, how often — note 06, Q20 *(planned)*

**Behavioural analytics and attack phases**

- [ ] Name the phases of an attack and the Kubernetes signal that reveals each — note 06
- [ ] Choose the right evidence source for a given question — note 06

**Immutability**

- [ ] Set `readOnlyRootFilesystem` and add the emptyDir mounts the app still needs — note 06, Q18
- [ ] Find and remove privileged or data-storing pods — note 06, Q18

---

## Tool mastery

Can you run each of these from memory, with no documentation, under time pressure? Trivy, kube-bench, kubesec, kube-linter and AppArmor have **no allowed documentation in the exam**, so the memory column is the only one that counts.

| Tool | Docs allowed in exam | `[ ]` |
|---|---|---|
| `kubectl` including `auth can-i`, `explain`, `-o jsonpath` | yes, kubernetes.io | [ ] |
| `yq` for JSON and YAML, standing in for the absent `jq` | no | [ ] |
| `crictl ps`, `inspect`, `logs` | no | [ ] |
| `etcdctl get` with `--cacert`, `--cert`, `--key` | yes, etcd.io | [ ] |
| `kube-bench run --targets --check` | **no** | [ ] |
| `trivy image --severity` | **no** | [ ] |
| `kubesec scan` and `kube-linter lint` | **no** | [ ] |
| `bom generate` and `bom document outline` | yes, bom CLI reference | [ ] |
| `apparmor_parser`, `aa-status` | **no** | [ ] |
| seccomp profile JSON by hand | yes, kubernetes.io | [ ] |
| `falco --list`, rule syntax, reload | yes, falco.org | [ ] |
| `openssl req`, `x509 -noout -subject -dates`, `s_client` | no | [ ] |
| `sha512sum --check` | no | [ ] |
| `strace -p -f -e trace=` | no | [ ] |
| `podman build` and `podman run` | no | [ ] |
| `cosign verify` | no | [ ] |
| Cilium: `cilium status`, `cilium encrypt status`, CiliumNetworkPolicy | yes, docs.cilium.io | [ ] |
| Istio: PeerAuthentication | yes, istio.io | [ ] |
| `systemctl`, `journalctl -u`, `ss -tlpn` | no | [ ] |

## Paths to recite

- [ ] `/etc/kubernetes/manifests/kube-apiserver.yaml`
- [ ] `/var/lib/kubelet/config.yaml`
- [ ] `/var/lib/kubelet/seccomp/profiles/`
- [ ] `/etc/apparmor.d/`
- [ ] `/etc/falco/falco_rules.yaml` and `/etc/falco/falco_rules.local.yaml` and `/etc/falco/falco.yaml`
- [ ] `/etc/kubernetes/audit/policy.yaml`
- [ ] `/etc/kubernetes/pki/etcd/{ca.crt,server.crt,server.key}`
- [ ] `/etc/kubernetes/admission-controllers/`
- [ ] `/var/log/pods/` for a crashed static pod
- [ ] `/opt/course/<n>/` where deliverables are written

---

## Re-score log

| Date | `[x]` count | Weakest domain | Action |
|---|---|---|---|
| 8 Nov 2026 | | | |
| 29 Nov 2026 | | | |
| 5 Dec 2026 | | | |
