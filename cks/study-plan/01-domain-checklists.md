# CKS Domain & Tool Mastery Checklists

Your progress tracker. Mark each item:
`[ ]` not started · `[~]` learned the concept · `[x]` **can do it timed (≤8 min) and closed-book**.
**You're exam-ready when nearly everything is `[x]`.** Re-score at Day 15, Day 35, and after each killer.sh session.

---

## Domain 1 — Cluster Setup (15%)

- [ ] NetworkPolicy: default-deny **ingress and egress**
- [ ] NetworkPolicy: selective allow with `podSelector` / `namespaceSelector` / `ipBlock` / `ports`
- [ ] NetworkPolicy: **always allow port-53 UDP+TCP egress** under a deny-all (DNS trap)
- [ ] NetworkPolicy: block pod access to cloud metadata IP (`ipBlock` cidr + `except`)
- [ ] kube-bench: run (`--targets master,node`), read FAIL findings, remediate, re-run
- [ ] CIS Benchmark: map a finding to the right component config (apiserver/kubelet/etcd flags)
- [ ] Ingress TLS: create `kubernetes.io/tls` secret (openssl), reference in `spec.tls`
- [ ] Verify a Kubernetes binary against its published `sha256`/`sha512` checksum
- [ ] Minimize dashboard/GUI exposure (RBAC, no default-admin binding)

## Domain 2 — Cluster Hardening (15%)

- [ ] RBAC: Role / ClusterRole / RoleBinding / ClusterRoleBinding, least-privilege
- [ ] RBAC: verify with `kubectl auth can-i ... --as=system:serviceaccount:ns:sa`
- [ ] RBAC: troubleshoot/repair an over- or under-permissioned binding
- [ ] ServiceAccount: `automountServiceAccountToken: false` (SA and pod level)
- [ ] ServiceAccount: per-workload SA (not `default`); `kubectl create token`
- [ ] API-server flags: `--anonymous-auth=false`, `--authorization-mode=Node,RBAC`
- [ ] API-server: enable admission plugins (`NodeRestriction`, `PodSecurity`) **+ volumes/mounts**
- [ ] API-server: **safe-edit procedure** + recover from a broken manifest (crictl/journalctl)
- [ ] `kubeadm upgrade plan` / `apply`; drain → uncordon workflow
- [ ] Approve/deny a CertificateSigningRequest

## Domain 3 — System Hardening (10%)

- [ ] Disable/remove services & close ports (`systemctl`, `apt remove`, `ss -tlnp`)
- [ ] Blacklist kernel modules (`/etc/modprobe.d/`, `lsmod`, `modprobe`)
- [ ] Restrict users/SSH (`usermod -s /bin/nologin`, `gpasswd -d`, sudoers); UFW basics
- [ ] **AppArmor**: load profile (`apparmor_parser -q`), `aa-status`, apply to pod (1.30+ field & legacy annotation)
- [ ] **seccomp**: `RuntimeDefault`; custom JSON at `/var/lib/kubelet/seccomp/profiles/` via `Localhost`
- [ ] Linux capabilities: `drop: ["ALL"]` then `add` only what's needed
- [ ] securityContext: correct pod-level vs container-level placement

## Domain 4 — Minimize Microservice Vulnerabilities (20%)

- [ ] Pod Security Admission: namespace labels `enforce`/`audit`/`warn`
- [ ] Pod Security Standards: privileged vs baseline vs **restricted** requirements
- [ ] OPA Gatekeeper: apply `ConstraintTemplate` + `Constraint` (basic)
- [ ] Kyverno: `ClusterPolicy` validate / verifyImages (basic; deep Rego *not* needed)
- [ ] Secrets encryption at rest: `EncryptionConfiguration` (aescbc) + apiserver flag
- [ ] Secrets: **re-encrypt** existing (`get secrets -A -o json | kubectl replace -f -`)
- [ ] Verify encryption in etcd with `etcdctl` (`k8s:enc:aescbc:` prefix)
- [ ] RuntimeClass / runtime sandbox (`handler: runsc`, `spec.runtimeClassName`)
- [ ] mTLS concept via Cilium / Istio (`mtls.mode: STRICT`) — doc-navigable
- [ ] Immutable containers: `readOnlyRootFilesystem: true` + emptyDir for writable paths

## Domain 5 — Supply Chain Security (20%)

- [ ] Minimal base images: distroless/alpine/scratch, multi-stage, non-root USER, pinned tags
- [ ] **Trivy**: `image --severity HIGH,CRITICAL`; `fs`; `config`; interpret + remediate
- [ ] Find vulnerable image in a running cluster and swap it out
- [ ] kubesec: `scan` a manifest, fix findings
- [ ] kube-linter: `lint` a manifest
- [ ] SBOM: `bom generate -n <image>` (SPDX); concept of CycloneDX
- [ ] Cosign: `sign` / `verify` an image
- [ ] ImagePolicyWebhook: AdmissionConfiguration + kubeconfig + apiserver plugin
- [ ] Allowed-registry enforcement via Kyverno/Gatekeeper policy

## Domain 6 — Monitoring, Logging & Runtime Security (20%)

- [ ] Falco: install; read default rules; locate `/etc/falco/falco_rules.local.yaml`
- [ ] Falco: **write a custom rule** (rule/desc/condition/output/priority)
- [ ] Falco: modify an existing rule's output format; redirect logs to a file
- [ ] Falco: reload without full restart; parse `journalctl -fu falco`
- [ ] Audit policy: levels None/Metadata/Request/RequestResponse
- [ ] Audit policy: **specific rules before catch-all (first match wins)**
- [ ] Audit: wire apiserver flags + **volumes/volumeMounts**; tail & `jq` the log
- [ ] Behavioral/threat detection: recognize shell-in-container, write-below-binary-dir, unexpected outbound
- [ ] Container immutability as a runtime control

---

## Master Tool Checklist

Mark `[x]` when you can use each from memory under time pressure.

| Tool | Domain(s) | Must be able to |
|------|-----------|-----------------|
| [ ] `kube-bench` | Setup | run, read FAIL, remediate |
| [ ] NetworkPolicy | Setup | deny-all + DNS egress + selectors |
| [ ] `openssl` | Setup/Hardening | gen cert, TLS secret |
| [ ] `kubectl` RBAC + `auth can-i` | Hardening | roles + `--as` verification |
| [ ] `kubeadm` | Hardening | upgrade plan/apply, drain |
| [ ] apiserver manifest edits | Hardening | flags + volumes, safe-edit, recover |
| [ ] `apparmor_parser` / `aa-status` | System | load + verify + apply to pod |
| [ ] seccomp JSON profiles | System | RuntimeDefault + Localhost |
| [ ] `etcdctl` | Hardening/Micro | read encrypted secret bytes |
| [ ] Pod Security Admission | Micro | namespace labels, 3 profiles |
| [ ] OPA Gatekeeper | Micro/Supply | template + constraint |
| [ ] Kyverno | Micro/Supply | ClusterPolicy validate/verifyImages |
| [ ] EncryptionConfiguration | Micro | aescbc + flag + re-encrypt |
| [ ] RuntimeClass (runsc) | Micro | manifest + runtimeClassName |
| [ ] `trivy` | Supply | image/fs/config + severity |
| [ ] `kubesec` / `kube-linter` | Supply | scan/lint + fix |
| [ ] `bom` (SBOM) | Supply | generate SPDX |
| [ ] `cosign` | Supply | sign/verify |
| [ ] ImagePolicyWebhook | Supply | admission config wiring |
| [ ] `falco` | Runtime | custom rule, reload, parse |
| [ ] audit policy | Runtime/Hardening | levels + first-match order + mounts |
| [ ] Linux (`systemctl`,`journalctl`,`modprobe`,`usermod`,`ss`) | System | node hardening fluency |
| [ ] `crictl` | Hardening/Runtime | `ps`, `logs`, `inspect` for debugging |
| [ ] `jq` | Runtime | parse audit/Falco JSON |

---

## Critical file paths to memorize (you *will* need these)

| Path | What |
|------|------|
| `/etc/kubernetes/manifests/kube-apiserver.yaml` | API-server static pod manifest |
| `/var/lib/kubelet/config.yaml` | kubelet config |
| `/var/lib/kubelet/seccomp/profiles/` | seccomp profiles |
| `/etc/apparmor.d/` | AppArmor profiles |
| `/etc/falco/falco_rules.local.yaml` | Falco custom rules |
| `/etc/kubernetes/audit/` | audit policy + log (your chosen dir) |
| `/etc/kubernetes/pki/etcd/` | etcd certs (for `etcdctl`) |
| `/etc/modprobe.d/` | kernel module blacklists |
