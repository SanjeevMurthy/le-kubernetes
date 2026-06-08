# CKS 45-Day Daily Schedule

**Legend:** 🎥 KodeKloud (Mumshad CKS) · 🧪 killercoda *killer-shell-cks* · 🖥️ your kubeadm cluster (node-level task — can't be done on kind) · 📇 Anki · 🔁 spaced review · ⏱️ timed (≤8 min/task) · 📌 bookmark the doc

Every day starts with **15 min 📇 Anki** and ends with **15 min close-book recall → new cards** (see the ritual in [README](README.md)). The work below is the *main block*.

> **Pace:** Days 1–15 = 2 h/day · Days 16–45 = 1 h/day. If your real schedule slips, **protect the daily Anki + one timed scenario** above all else — that's the spaced-repetition backbone.

---

## Phase 0 — Setup (do before Day 1, ~45 min, one-time)

- [ ] **Register & book the CKS exam** for ~Day 45 (unlocks 2 killer.sh sessions). [`02-resources.md`](02-resources.md)
- [ ] Build your practice cluster: 2-node **kubeadm** (Multipass/Vagrant or a cloud VM, Ubuntu 22.04/24.04). Node-level tasks need this. [`02-resources.md`](02-resources.md#practice-cluster)
- [ ] Create accounts: killercoda, KodeKloud; install **Anki** (or Anki-style app).
- [ ] Import the doc **bookmarks** from [`02-resources.md`](02-resources.md#exam-allowed-documentation--bookmark-these) into your browser bar.
- [ ] Save your `.bashrc` aliases + `.vimrc` from [`03-exam-day-playbook.md`](03-exam-day-playbook.md) onto the cluster so you practice with them daily.

---

## Phase 1 — Foundation (Days 1–15, 2 h/day)

Goal: touch **all 6 domains once, hands-on**, building the Anki deck and muscle memory. System Hardening & Runtime Security get extra room because you're new to them. **Type everything; no copy-paste this phase.**

### Week 1 — Cluster Setup, Cluster Hardening, System Hardening basics

**Day 1 — Orientation + NetworkPolicy** (Cluster Setup)
- 🎥 Intro + exam overview; 🎥 NetworkPolicy section.
- 🖥️ Build a **default-deny ingress+egress** policy, then selectively allow. **Always add the port-53 UDP/TCP egress rule** or you'll break DNS (classic exam trap).
- 🧪 killercoda NetworkPolicy scenario. 📌 NetworkPolicies doc.
- 📇 Cards: policy YAML skeleton, podSelector vs namespaceSelector vs ipBlock, DNS egress snippet.

**Day 2 — CIS / kube-bench, Ingress TLS, metadata** (Cluster Setup)
- 🎥 CIS Benchmarks + kube-bench; Ingress TLS; node metadata protection.
- 🖥️ Run `kube-bench run --targets master,node`; fix 2–3 FAIL findings (apiserver/kubelet flags); re-run to confirm.
- 🖥️ Create a `kubernetes.io/tls` secret with openssl; wire it into an Ingress `spec.tls`.
- 🖥️ Block pod access to the metadata IP (`169.254.169.254`) with a NetworkPolicy `ipBlock` + `except`.
- 📇 Cards: kube-bench targets, openssl cert cmd, TLS secret type, metadata CIDR.

**Day 3 — RBAC + ServiceAccounts** (Cluster Hardening)
- 🎥 RBAC; ServiceAccounts.
- 🖥️ Build least-privilege Role/RoleBinding; verify with `kubectl auth can-i ... --as=system:serviceaccount:ns:sa`.
- 🖥️ Disable token automount (`automountServiceAccountToken: false`) at SA and pod level; `kubectl create token`.
- 🧪 killercoda RBAC scenario. 📌 RBAC + RBAC Good Practices docs.
- 📇 Cards: Role vs ClusterRole, `auth can-i --as`, automount flag, create token.

**Day 4 — API-server hardening + upgrades** (Cluster Hardening)
- 🎥 Securing the API server; cluster upgrades; CSRs.
- 🖥️ **Back up** `/etc/kubernetes/manifests/kube-apiserver.yaml`, then practice editing flags safely: `--anonymous-auth=false`, `--authorization-mode=Node,RBAC`, add an admission plugin. Watch it restart with `crictl ps | grep api`. **Recover from a deliberately broken manifest** (read `journalctl -u kubelet`).
- 🖥️ Walk through `kubeadm upgrade plan` (read-only is fine); approve a CSR.
- 📇 Cards: secure apiserver flags, safe-edit procedure, restart-watch cmd, NodeRestriction.

**Day 5 — Linux/System Hardening fundamentals** ⭐ extra time (System Hardening)
- 🎥 System Hardening intro + Linux security.
- 🖥️ Services/ports: `systemctl disable --now`, `apt remove`, audit ports with `ss -tlnp`. Users: `useradd/usermod -s /bin/nologin`, `gpasswd -d`. Kernel modules: blacklist in `/etc/modprobe.d/`, `lsmod`/`modprobe`. UFW basics.
- 🖥️ Linux **capabilities**: `drop: ["ALL"]` then `add` only what's needed.
- 📇 Cards: each command above, capability drop/add pattern, securityContext pod-vs-container placement.

**Day 6 — AppArmor** ⭐ (System Hardening) 🖥️ real node required
- 🎥 AppArmor.
- 🖥️ Load a profile with `apparmor_parser -q`; check `aa-status`; apply to a pod (1.30+: `securityContext.appArmorProfile`; older: the annotation). Trigger enforce/complain modes.
- 🧪 killercoda AppArmor scenario ⏱️.
- 📌 Linux kernel security constraints doc. 📇 Cards: load cmd, aa-status, profile path `/etc/apparmor.d/`, pod field vs annotation.

**Day 7 — seccomp + Week-1 review** ⭐ (System Hardening)
- 🎥 seccomp.
- 🖥️ Apply `RuntimeDefault`; write a custom JSON profile at `/var/lib/kubelet/seccomp/profiles/`, apply via `Localhost`. Confirm with `crictl inspect`.
- 🔁 **Mixed mini-mock (45 min ⏱️):** one task each from Cluster Setup, Cluster Hardening, System Hardening — closed book.
- 📇 Cards: seccomp types, profile path, Localhost field. Review all Week-1 cards.

### Week 2 — Microservice Vulns, Supply Chain, Runtime Security

**Day 8 — Pod Security Admission/Standards** (Microservice Vulns)
- 🎥 PSA/PSS (the PSP replacement — **don't study PSP**).
- 🖥️ Label namespaces `pod-security.kubernetes.io/{enforce,audit,warn}: restricted`; test a violating pod; read the 3 profiles (privileged/baseline/restricted).
- 🖥️ Deep securityContext: `runAsNonRoot`, `readOnlyRootFilesystem`, `allowPrivilegeEscalation: false`.
- 🔁 Spaced review: Day 1 NetworkPolicy + Day 3 RBAC cards.
- 📌 PSA + PSS docs. 📇 Cards: the 3 label modes, 3 profiles, key restricted-profile requirements.

**Day 9 — OPA Gatekeeper + Kyverno** (Microservice Vulns)
- 🎥 Admission controllers; OPA Gatekeeper; Kyverno.
- 🖥️ Gatekeeper: apply a `ConstraintTemplate` + `Constraint` (e.g., block privileged pods). Kyverno: a `ClusterPolicy` `validate` rule (e.g., require non-root). *Know basic apply — deep Rego is rarely tested, so don't over-invest.*
- 🧪 killercoda OPA scenario ⏱️.
- 📇 Cards: ConstraintTemplate vs Constraint, Kyverno rule types (validate/mutate/generate/verifyImages).

**Day 10 — Secrets encryption at rest** (Microservice Vulns)
- 🎥 Secrets; encrypting data at rest.
- 🖥️ Write `EncryptionConfiguration` (aescbc), wire `--encryption-provider-config` into apiserver, **re-encrypt** existing secrets: `kubectl get secrets -A -o json | kubectl replace -f -`. Verify raw bytes in etcd with `etcdctl` (`k8s:enc:aescbc:` prefix).
- 🔁 Spaced review: Day 4 apiserver-flags + Day 2 kube-bench cards.
- 📌 Encrypt Data at Rest doc. 📇 Cards: EncryptionConfiguration shape, re-encrypt one-liner, etcdctl verify cmd.

**Day 11 — Runtime sandboxes + mTLS + immutability** (Microservice Vulns)
- 🎥 gVisor/RuntimeClass; container runtime sandboxes; mTLS concepts.
- 🖥️ Create a `RuntimeClass` (`handler: runsc`), reference via `spec.runtimeClassName`. (If runsc isn't installed, study the manifest + RuntimeClass doc — it's moderate-priority.) Skim Cilium/Istio mTLS (`mtls.mode: STRICT`) at the *doc* level — exam tasks here are doc-navigable.
- 📌 RuntimeClass + Cilium + Istio docs. 📇 Cards: RuntimeClass fields, runtimeClassName, Istio STRICT.

**Day 12 — Image footprint + Trivy** (Supply Chain)
- 🎥 Supply Chain intro; minimizing base images; Trivy.
- 🖥️ Multi-stage Dockerfile → distroless/alpine, non-root USER, pinned tags. ⏱️ `trivy image --severity HIGH,CRITICAL <img>`; find the vulnerable pod in a cluster, swap to a clean image.
- 🧪 killercoda Trivy scenario ⏱️.
- 📌 Trivy CKS tutorial. 📇 Cards: trivy subcommands (`image`/`fs`/`config`), severity flag, image-audit `custom-columns` cmd.

**Day 13 — Static analysis, SBOM, signing, ImagePolicyWebhook** (Supply Chain)
- 🎥 kubesec/kube-linter; SBOM; image policy.
- 🖥️ `kubesec scan pod.yaml` → fix findings. `kube-linter lint`. Generate an SBOM with `bom generate`. `cosign sign`/`verify`. Configure **ImagePolicyWebhook** (AdmissionConfiguration + kubeconfig + apiserver plugin) and/or a Kyverno allowed-registry policy.
- 🔁 Spaced review: Day 5–7 (Linux/AppArmor/seccomp) cards.
- 📌 bom CLI reference. 📇 Cards: kubesec scan, bom generate, ImagePolicyWebhook wiring, allowed-registry policy.

**Day 14 — Falco** ⭐⭐ (Runtime Security) 🖥️ real node required
- 🎥 Falco (install, rules, outputs).
- 🖥️ Install Falco; read default rules; **write a custom rule** in `/etc/falco/falco_rules.local.yaml` (rule/desc/condition/output/priority); trigger it (e.g., shell in container, write below binary dir); reload **without full restart** (`kill -1 $(cat /var/run/falco.pid)`); parse `journalctl -fu falco`. Modify an existing rule's output format & redirect to a file.
- 🧪 killercoda Falco scenario ⏱️.
- 📌 falco.org/docs. 📇 Cards: rule fields, condition filters (`evt.type`,`proc.name`,`fd.name`,`container.name`), reload cmd, local rules path.

**Day 15 — Audit logging + Phase-1 self-assessment** ⭐ (Runtime Security)
- 🎥 Audit logging.
- 🖥️ Write an audit **policy** (levels None/Metadata/Request/RequestResponse; **specific rules before catch-all — first match wins**); wire `--audit-policy-file` + `--audit-log-path` + **the matching `volumes`/`volumeMounts`** into apiserver (forgetting mounts breaks it). Tail & `jq` the audit log.
- 🔁 **Self-assessment:** run the [`01-domain-checklists.md`](01-domain-checklists.md) tracker. Anything still `[ ]`/`[~]` → it gets priority in Phase 2.
- 📌 Audit Logging doc. 📇 Cards: 4 audit levels, rule-order rule, apiserver audit flags + volume requirement.

---

## Phase 2 — Consolidation (Days 16–35, 1 h/day)

Goal: convert knowledge into **fast, closed-book, interleaved execution**. Each day = 15 min 📇 + ~40 min ⏱️ practice + 5 min log misses to your **drill list**. Sources rotate: killercoda, then closed-book GitHub exercise sets (bmuschko/cks-crash-course, moabukar/CKS-Exercises). **Interleave — never two same-subdomain tasks back-to-back.** Weekends do the 🖥️ node-only tasks.

> Each day lists an **interleaved trio** (pick 3 timed tasks across different domains) + a **🔁 spaced-review** target from Phase 1. Mocks on Days 21, 28, 35.

**Day 16** — Trio: NetworkPolicy(deny+DNS) · RBAC verify · Trivy scan. 🔁 PSA labels.
**Day 17** — Trio: seccomp Localhost · kube-bench fix · Kyverno validate. 🔁 apiserver flags.
**Day 18** — Trio: AppArmor apply 🖥️ · audit-policy order · ServiceAccount automount. 🔁 encryption-at-rest.
**Day 19** — Trio: Falco custom rule 🖥️ · Ingress TLS · PSA enforce. 🔁 capabilities drop/add.
**Day 20** — Trio: EncryptionConfig + re-encrypt · Gatekeeper constraint · metadata NetworkPolicy. 🔁 Falco fields.
**Day 21 — ⏱️ Mixed mock #1 (60 min):** full closed-book set from bmuschko/cks-crash-course across ≥5 domains. Annotate every miss → drill list.
**Day 22** — Drill-list day: redo your 3 weakest Day-21 tasks until <8 min each. 🔁 audit levels.
**Day 23** — Trio: kubesec fix · seccomp RuntimeDefault · RBAC ClusterRole. 🔁 NetworkPolicy DNS.
**Day 24** — Trio: ImagePolicyWebhook 🖥️ · Falco modify-output 🖥️ · readOnlyRootFilesystem. 🔁 kube-bench.
**Day 25** — Trio: RuntimeClass/gVisor · audit log + jq · allowed-registry Kyverno. 🔁 AppArmor cmds.
**Day 26** — Trio: CSR approve · NetworkPolicy namespaceSelector · cosign verify. 🔁 PSS profiles.
**Day 27** — Trio: apiserver safe-edit + recover 🖥️ · kube-bench node 🖥️ · Trivy fs/config. 🔁 encryption verify.
**Day 28 — ⏱️ Mixed mock #2 (60 min):** moabukar/CKS-Exercises set, ≥5 domains, closed-book. Annotate → drill list.
**Day 29** — Drill-list day: weakest Day-28 tasks. 🔁 Falco reload.
**Day 30** — Trio: PSA audit+warn · seccomp custom 🖥️ · OPA template. 🔁 RBAC auth can-i.
**Day 31** — Trio: SBOM bom generate · NetworkPolicy egress · AppArmor complain 🖥️. 🔁 audit volume mounts.
**Day 32** — Trio: secrets-at-rest etcdctl 🖥️ · Ingress TLS · Kyverno mutate. 🔁 capabilities.
**Day 33** — Trio: Falco from-scratch rule 🖥️ · kubesec · metadata block. 🔁 RuntimeClass.
**Day 34** — Trio: audit policy multi-rule · RBAC aggregate · Trivy in-cluster. 🔁 PSA labels (final).
**Day 35 — ⏱️ Mixed mock #3 (60 min):** mix sources; simulate exam conditions (timer, only allowed docs open). Re-score the [domain checklist](01-domain-checklists.md). Target: most items `[x]`.

---

## Phase 3 — Simulation & Polish (Days 36–45, 1 h/day)

Goal: exam-condition speed, docs-navigation reflexes, and confidence calibration via killer.sh.

**Day 36** — Docs-speed drill: from each [bookmark](02-resources.md#exam-allowed-documentation--bookmark-these), find a specific snippet in <60 s (PSA labels, seccomp YAML, audit policy, Falco rule, EncryptionConfiguration). 🔁 drill-list weakest 3.
**Day 37** — Targeted remediation of your 3 weakest domains from Day-35 checklist (closed-book ⏱️).
**Day 38 — 🔬 killer.sh Session 1 (full 120 min if you can spare it once; otherwise split across Day 38–39).** Don't peek at solutions until done. Expect it to feel *harder* than the real exam — 60–70% here ≈ on track.
**Day 39** — Review **every** killer.sh Session-1 solution; for each miss, do the task again from scratch 🖥️/🧪. Add cards.
**Day 40** — Re-drill the killer.sh topics you failed until each is <8 min. 🔁 full Anki sweep.
**Day 41** — Interleaved timed set focused on the **20%-weight trio** (Microservice / Supply Chain / Runtime) — that's 60% of the exam. ⏱️
**Day 42** — Exam-logistics rehearsal: set up `.bashrc`+`.vimrc` from cold in <2 min; practice context-switch+verify (`kubectl config use-context X && kubectl get nodes`) reflex; review the [exam-day playbook](03-exam-day-playbook.md) gotchas + Top-15.
**Day 43** — Light: 🔁 full Anki, re-skim weakest domain, **rest your brain** (no new material). Confirm exam system check (PSI browser, webcam, ID, clean desk).
**Day 44 — 🔬 killer.sh Session 2 (warm-up, timed).** Treat as final calibration, not learning. Review solutions same day. Stop studying new things.
**Day 45 — 🎯 EXAM DAY.** Light Anki only. Run the [exam-day playbook](03-exam-day-playbook.md): aliases first, context-switch+verify every question, three-pass triage, verify every task, don't reboot the base node, `Ctrl+Alt+W` (not `Ctrl+W`).

---

## If your timeline changes

- **Compress to ~30 days:** keep Phase 1 intact (the foundation is non-negotiable for a beginner), merge Phase 2 into ~10 days (Days 16–25: one mock at Day 22), run Phase 3 in Days 26–30 with killer.sh on Days 28 & 29.
- **Extend to ~60 days:** stretch Phase 2 to 1.5 h/day or add a 4th mock; spend extra time on the 20%-weight trio and on 🖥️ node tasks (AppArmor/seccomp/Falco/audit) where beginners lose the most points.
- **Fell behind?** Protect, in order: (1) daily Anki, (2) Falco + audit + apiserver-edit reps, (3) one timed mixed scenario. Drop video re-watching first — re-execute scenarios instead.
