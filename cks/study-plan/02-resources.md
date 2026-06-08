# CKS Resources

Curated and de-duplicated from research across the official curriculum, 12 first-hand "I passed" debriefs, and hands-on lab catalogs. Prioritized for **your** stack: KodeKloud + killer.sh + free.

## Tier 1 — Use these (your core path)

| Resource | Cost | Role in your plan | URL |
|----------|------|-------------------|-----|
| **KodeKloud — CKS (Mumshad)** | Paid (you have it) | **Anchor** for daily theory + in-browser labs + mock exams | https://kodekloud.com/courses/certified-kubernetes-security-specialist-cks/ |
| **killer.sh CKS simulator** | Free w/ exam voucher | **Final calibration** — 2 sessions, harder than real exam; use Day 38 & Day 44 | https://killer.sh/cks |
| **killercoda — killer-shell-cks** | Free | **Daily timed reps** (AppArmor, Falco, audit, OPA, seccomp, NetworkPolicy) | https://killercoda.com/killer-shell-cks |
| **Kubernetes docs (security)** | Free | Only reference allowed in-exam — learn to navigate fast | https://kubernetes.io/docs/concepts/security/ |
| **KodeKloud CKS course notes (GitHub)** | Free | Command reference alongside the videos | https://github.com/kodekloudhub/certified-kubernetes-security-specialist-cks-course |

## Tier 2 — Closed-book exercise sets (Phase 2 mocks)

| Resource | Why | URL |
|----------|-----|-----|
| **bmuschko/cks-crash-course** | Numbered exercises + solutions, performance-based; great for Mock #1 (Day 21) | https://github.com/bmuschko/cks-crash-course |
| **moabukar/CKS-Exercises** | Per-domain labs incl. AppArmor/seccomp/Falco/Trivy/OPA/gVisor; Mock #2 (Day 28) | https://github.com/moabukar/CKS-Exercises-Certified-Kubernetes-Security-Specialist |
| **Kim Wüstkamp — free 11–13h CKS YouTube** | Same author as killer.sh; free fallback for any weak topic | https://www.youtube.com/watch?v=d9xfB5qaOfg |
| **killer-sh/cks-course-environment** | Scripts to stand up the 2-node practice cluster | https://github.com/killer-sh/cks-course-environment |

## Tier 3 — Reference & depth (dip in as needed)

| Resource | URL |
|----------|-----|
| techiescamp/cks-certification-guide (shortcuts, revision cmds) | https://github.com/techiescamp/cks-certification-guide |
| stackrox CKS study guide (cluster build + Q&A) | https://github.com/stackrox/Kubernetes_Security_Specialist_Study_Guide |
| Trivy official CKS tutorial | https://aquasecurity.github.io/trivy/v0.33/tutorials/additional-resources/cks/ |
| aquasecurity/kube-bench | https://github.com/aquasecurity/kube-bench |
| OPA Gatekeeper docs | https://open-policy-agent.github.io/gatekeeper/ |
| Liz Rice — *Container Security* (book, for depth) | O'Reilly |
| Zeal Vora — CKS (Udemy, alt course w/ from-scratch cluster) | https://www.udemy.com/course/certified-kubernetes-security-specialist-certification/ |

---

## Practice cluster

**Recommendation: a 2-node `kubeadm` cluster** (Ubuntu 22.04/24.04, kernel 5.15+). Control plane 2 vCPU/4 GB, worker 2 vCPU/2–4 GB. Local via **Multipass/Vagrant+VirtualBox**, or cloud (GCP e2-medium ~$15/mo, DigitalOcean ~$12/mo). Scripts: [killer-sh/cks-course-environment](https://github.com/killer-sh/cks-course-environment).

**Why not just kind/minikube?** These node-level tasks need real systemd nodes you can SSH into and edit — they **cannot** be practiced reliably on kind:

| Needs real kubeadm node | Reason |
|---|---|
| AppArmor profiles | profile loaded on host OS, kubelet reads from node FS |
| seccomp profiles on node | live at `/var/lib/kubelet/seccomp/` on the actual node |
| gVisor / `runsc` RuntimeClass | `runsc` binary + containerd config edit on node |
| kube-bench CIS scan | reads host files + running processes |
| API-server audit log + flag edits | edit static-pod manifest on control-plane node |
| kubelet hardening | edit kubelet config + `systemctl restart` |
| Falco | installs kernel module / eBPF probe on node |
| etcd encryption at rest | edit apiserver manifest on control-plane node |
| SSH/UFW/kernel-module hardening | host-OS tasks |

**Fine on kind** (fast iteration, ~40% of coverage): NetworkPolicy (with Calico/Cilium CNI), RBAC, PSA, OPA/Gatekeeper, Kyverno, Trivy (CLI), secrets, admission webhooks, ServiceAccounts.

**Hybrid (recommended):** daily drills on killercoda/KodeKloud (no setup); reserve the kubeadm cluster for the node-only tasks above — batch them on weekends (Phase 2 marks these 🖥️).

---

## Exam-allowed documentation — bookmark these

During the exam, **only** these domains may be open (source: Linux Foundation "Resources Allowed"). Build the bookmark bar now and practice finding snippets in <60 s.

**Allowed domains:**
- `https://kubernetes.io/docs/` and `https://kubernetes.io/blog/`
- `https://falco.org/docs/`
- `https://etcd.io/docs/`
- `https://kubernetes-sigs.github.io/bom/cli-reference/`
- `https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/`
- `https://docs.cilium.io/en/stable`
- `https://istio.io/latest/docs/`

> ⚠️ **Trivy docs** (`aquasecurity.github.io/trivy`) appear in some third-party lists but were **not** on the official allowed page at research time — don't rely on them in-exam; memorize the Trivy commands instead. Re-check the official page before your exam date.

**Exact kubernetes.io pages to pin** (these recur in real tasks):

| Topic | Path |
|------|------|
| Pod Security Standards | `/docs/concepts/security/pod-security-standards/` |
| Pod Security Admission | `/docs/concepts/security/pod-security-admission/` |
| Network Policies | `/docs/concepts/services-networking/network-policies/` |
| RBAC | `/docs/reference/access-authn-authz/rbac/` |
| RBAC Good Practices | `/docs/concepts/security/rbac-good-practices/` |
| Audit Logging | `/docs/tasks/debug/debug-cluster/audit/` |
| Admission Controllers | `/docs/reference/access-authn-authz/admission-controllers/` |
| RuntimeClass | `/docs/concepts/containers/runtime-class/` |
| Seccomp tutorial | `/docs/tutorials/security/seccomp/` |
| Linux kernel security constraints (AppArmor) | `/docs/concepts/security/linux-kernel-security-constraints/` |
| Encrypt Data at Rest | `/docs/tasks/administer-cluster/encrypt-data/` |
| Secrets Good Practices | `/docs/concepts/security/secrets-good-practices/` |
| Controlling Access to the API | `/docs/concepts/security/controlling-access/` |
| Security Checklist | `/docs/concepts/security/security-checklist/` |

**CIS / kube-bench:** kube-bench repo (run as a Job) + CIS Kubernetes Benchmark PDF (free w/ registration at cisecurity.org).

---

## Exam facts (verify on the official page before sitting)

- **Format:** performance-based, CLI only · **2 hours** · ~15–17 weighted tasks · **67% to pass** · results in 24 h.
- **K8s version:** v1.34 (tracks current release; updates 4–8 weeks after each).
- **Prerequisite:** passed CKA (need not still be active).
- **Cost:** ~$445, includes **one free retake**; cert valid **2 years**; 12 months to sit after purchase.
- **Curriculum that applies = the one current on your exam date** (not purchase date).
- Official curriculum repo: https://github.com/cncf/curriculum (`CKS_Curriculum_v1.34.pdf`).
