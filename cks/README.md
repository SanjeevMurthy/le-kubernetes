# CKS - Certified Kubernetes Security Specialist

Performance-based, CLI-only exam. **2 hours, ~15–17 weighted tasks, 67% to pass.**
Prerequisite: a **passed CKA** (does not need to still be active). One free retake included.
Exam tracks the current Kubernetes release — **v1.34** as of this writing (curriculum updates 4–8 weeks after each K8s release).

## Exam Domains & Weights (post-Oct-2024 curriculum, v1.34)

| Domain | Weight |
|--------|--------|
| Minimize Microservice Vulnerabilities | 20% |
| Supply Chain Security | 20% |
| Monitoring, Logging and Runtime Security | 20% |
| Cluster Setup | 15% |
| Cluster Hardening | 15% |
| System Hardening | 10% |

> Note: older guides list Cluster Setup at 10% and System Hardening at 15% — that is the **pre-October-2024** split. The weights above are current.

## Key Topics

- **Cluster Setup (15%)**: NetworkPolicy (default-deny + DNS egress), CIS benchmark / kube-bench, Ingress TLS, node metadata protection, binary checksum verification
- **Cluster Hardening (15%)**: RBAC least-privilege, ServiceAccount token controls, API-server flags, NodeRestriction, `kubeadm upgrade`, CSRs
- **System Hardening (10%)**: OS footprint reduction, kernel module blacklisting, AppArmor, seccomp, Linux capabilities
- **Minimize Microservice Vulnerabilities (20%)**: Pod Security Admission/Standards (replaces PSP), OPA Gatekeeper, Kyverno, secrets encryption at rest, runtime sandboxes (gVisor/RuntimeClass), mTLS (Cilium/Istio), immutable containers
- **Supply Chain Security (20%)**: minimal base images, Trivy image scanning, kubesec/kube-linter static analysis, SBOM (bom/syft), Cosign, ImagePolicyWebhook, allowed-registry admission control
- **Monitoring, Logging & Runtime Security (20%)**: Falco (rules + reload + log parsing), API-server audit policy & logging, behavioral/threat detection, container immutability

## What's here

| Folder | What it is |
|--------|-----------|
| [`study-plan/`](study-plan/) | Evidence-based **45-day plan** — when to study what |
| [`study-notes/`](study-notes/) | Concise **per-domain study guides** (concepts + commands + exam gotchas), official curriculum order |
| [`practice-cli/`](practice-cli/) | Interactive **18-question practice harness** with setup/verify/cleanup, mirrors `cka/practice-cli` |

The three are cross-linked: read the **note** for a domain → drill the matching **practice-CLI** questions → on the cadence in the **plan**.

## Study Plan

See **[`study-plan/`](study-plan/)** for the full evidence-based plan:

- [`study-plan/README.md`](study-plan/README.md) — overview, phases, study principles, how to use
- [`study-plan/00-daily-schedule.md`](study-plan/00-daily-schedule.md) — 45-day day-by-day calendar
- [`study-plan/01-domain-checklists.md`](study-plan/01-domain-checklists.md) — per-domain competency + tool mastery trackers
- [`study-plan/02-resources.md`](study-plan/02-resources.md) — annotated resources, course mapping, cluster setup, doc bookmarks
- [`study-plan/03-exam-day-playbook.md`](study-plan/03-exam-day-playbook.md) — logistics, aliases/.vimrc, gotchas, top-15 lessons

## Study Notes

See **[`study-notes/`](study-notes/)** — six guides in curriculum order (Cluster Setup → Cluster Hardening → System Hardening → Microservice Vulnerabilities → Supply Chain → Monitoring/Runtime). Each covers what a topic is, why it matters, the commands, and the real exam gotchas.

## Practice CLI

See **[`practice-cli/`](practice-cli/)** — run `./cks` for 18 exam-style, security-focused scenarios with automated setup, PASS/FAIL verification, a timer, and per-question solutions. Requires Bash 4+ and a cluster (kubeadm recommended for node-level tasks).
