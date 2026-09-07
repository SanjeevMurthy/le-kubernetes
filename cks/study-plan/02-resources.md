# CKS Resources

What to use, what each thing is uniquely good for, and where the gaps are. Ratings come from 28 first-hand candidate write-ups summarised in [`../../docs/research/2026-09-06-cks-exam-research.md`](../../docs/research/2026-09-06-cks-exam-research.md).

<!-- toc -->
## Table of Contents

- [Tier 1: the ones that decide the outcome](#tier-1-the-ones-that-decide-the-outcome)
- [KodeKloud course to note mapping](#kodekloud-course-to-note-mapping)
- [Killercoda scenarios by domain](#killercoda-scenarios-by-domain)
- [Allowed documentation](#allowed-documentation)
  - [Page titles to search for](#page-titles-to-search-for)
- [Labs](#labs)
- [Free extras worth a look](#free-extras-worth-a-look)
- [What to skip](#what-to-skip)
- [Verify before you book](#verify-before-you-book)

<!-- toc stop -->

## Tier 1: the ones that decide the outcome

| Resource | Cost | What it uniquely gives you | Named by |
|---|---|---|---|
| **killer.sh simulator** | Included with the voucher | Two sessions of 17 questions each, **and the two sets are different**. Harder than the real exam by design. The remote desktop closely matches the real one. 36 hours of access per activation, with about 120 pages of solutions. | 20 of 28 write-ups |
| **KodeKloud CKS course and mocks** | Subscription you already hold | Guided first pass with in-browser root clusters, plus three auto-graded 16-task mocks | 15 of 28 |
| **Killercoda Killer Shell CKS** | Free | 42 scenarios on real kubeadm nodes with root. The best free stand-in for the exam environment. | 11 of 28 |
| **This repo** | Free | Timed questions with automated setup and verification, three mocks, and the recipes behind them | — |

**How to sequence killer.sh.** Session 1 on 28 November, two weeks out, treated as a diagnostic. Session 2 on 9 December, three days out, treated as a rehearsal. Do not activate early: the 36-hour clock starts on activation, and the questions stay readable afterwards.

## KodeKloud course to note mapping

Work one course section per foundation weekend, in the calendar's order rather than the course's order. The calendar front-loads Runtime Security because it is the least familiar and the heaviest reported.

| Weekend | KodeKloud section | Note |
|---|---|---|
| 26 to 27 Sep | Cluster Setup | [`../study-notes/01-cluster-setup.md`](../study-notes/01-cluster-setup.md) |
| 3 to 4 Oct | Monitoring, Logging and Runtime Security | [`../study-notes/06-monitoring-logging-runtime.md`](../study-notes/06-monitoring-logging-runtime.md) |
| 10 to 11 Oct | Cluster Hardening | [`../study-notes/02-cluster-hardening.md`](../study-notes/02-cluster-hardening.md) |
| 17 to 18 Oct | System Hardening | [`../study-notes/03-system-hardening.md`](../study-notes/03-system-hardening.md) |
| 24 to 25 Oct | Minimize Microservice Vulnerabilities | [`../study-notes/04-microservice-vulnerabilities.md`](../study-notes/04-microservice-vulnerabilities.md) |
| 31 Oct to 1 Nov | Supply Chain Security | [`../study-notes/05-supply-chain-security.md`](../study-notes/05-supply-chain-security.md) |

**Known KodeKloud gaps**, reported by candidates who used it as their only source: the TLS-protocol question between the API server and etcd, and the depth of Falco and Cilium work. One candidate who used only KodeKloud wrote that it alone is not enough for a high score. The repo questions and Killercoda cover those gaps.

## Killercoda scenarios by domain

All 42 free Killer Shell CKS scenarios at <https://killercoda.com/killer-shell-cks>, grouped by the domain they serve. Names are as they appear on the site.

**Setup and orientation:** Playground · Exam Desktop · Vim Setup · Playground Cilium Network Policy

**Cluster Setup:** NetworkPolicy Create Default Deny · NetworkPolicy Namespace Selector · NetworkPolicy Metadata Protection · CIS Benchmarks fix Controlplane · Ingress Create · Ingress Secure · Verify Platform Binaries

**Cluster Hardening:** RBAC User Permissions · RBAC ServiceAccount Permissions · ServiceAccount Token Mounting · Apiserver Crash · Apiserver Misconfigured · Apiserver NodeRestriction · CertificateSigningRequests sign manually · CertificateSigningRequests sign via API

**System Hardening:** AppArmor · System Hardening Close Open Ports · System Hardening Manage Packages · Privileged Containers · Privilege Escalation Containers · Container Hardening · Syscall Activity Strace

**Microservice Vulnerabilities:** Secret ETCD Encryption · Secret Read and Decode · Secret Access in Pods · Secret ServiceAccount Pod · Sandbox gVisor · Container Namespaces Docker · Container Namespaces Podman

**Supply Chain:** Image Vulnerability Scanning Trivy · Image Use Digest · Container Image Footprint User · Static Manual Analysis Docker · Static Manual Analysis K8s · ImagePolicyWebhook Setup

**Runtime Security:** Falco Change Rule · Auditing Enable Audit Logging · Immutability Readonly Filesystem

**What Killercoda does not cover**, so the repo questions carry it alone: Pod Security Admission, SBOM with `bom`, kubesec and kube-linter, Istio mTLS, ValidatingAdmissionPolicy, and the kubeadm cluster upgrade.

Free sessions are one hour. The PLUS tier adds four-hour sessions and an exam-style remote desktop, which one candidate bought specifically to rehearse the interface.

## Allowed documentation

The exam allows exactly eight sources and nothing else. Full detail and the reasoning in [`../study-notes/00-exam-environment.md`](../study-notes/00-exam-environment.md).

| Allowed | Not allowed |
|---|---|
| kubernetes.io/docs and /blog | Trivy documentation |
| falco.org/docs | kube-bench documentation |
| kubernetes-sigs.github.io/bom/cli-reference | AppArmor documentation |
| etcd.io/docs | kubesec and kube-linter documentation |
| kubernetes.github.io/ingress-nginx user guide | GitHub |
| docs.cilium.io | External search results |
| istio.io/latest/docs | Personal bookmarks |

Practise inside that boundary from the first weekend. Studying with a tool's own documentation open builds a habit you cannot use on the day.

### Page titles to search for

You navigate by searching kubernetes.io for a remembered title, because bookmarks are gone.

Auditing · Encrypting Confidential Data at Rest · Restrict a Container's Access to Resources with AppArmor · Restrict a Container's Syscalls with seccomp · Enforce Pod Security Standards with Namespace Labels · Network Policies · Using RBAC Authorization · Admission Controllers Reference · Runtime Class · Certificate Signing Requests · Upgrading kubeadm clusters

On falco.org: Supported Fields, and the rules reference. On docs.cilium.io: Network Policy, and Transparent Encryption.

Faster than any of them for field names: `kubectl explain pod.spec.securityContext --recursive`.

## Labs

Both tiers, with the commands to build them: [`../lab-setup/README.md`](../lab-setup/README.md).

In short, minikube with Calico on this Mac for everything that only needs `kubectl`, and the Killercoda playground for everything that needs root on a node. `./cks --env` tells you which questions the host you are on can actually run.

## Free extras worth a look

- **kyle-heller/CKS-PREP-2025** on GitHub: 55 scripted questions with setup and verify scripts, the closest public analogue to this repo's practice CLI.
- **ViktorUJ/cks**: 22 labs and four mock exams, and the only free source with Istio and TLS-cipher labs.
- **Kim Wüstkamp's CKS course**: the paid Udemy version has a free 11-hour YouTube edition from the author of killer.sh.
- **kodekloudhub/community-faq**: the crashed-API-server diagnosis notes are the best short write-up of that recovery.

## What to skip

- **LFS260**, the official Linux Foundation course. Not recommended by a single 2024 to 2026 write-up for someone who already holds the CKA.
- **Any site selling exam dumps.** They are inaccurate for a performance-based exam and using them breaches the certification agreement.
- **Guides listing Cluster Setup at 10 percent** or the Dashboard bullet. Those describe the pre-October-2024 curriculum and are stale.

## Verify before you book

Two official pages change without notice. Re-read both the week before booking and again the week before the exam:

- `https://docs.linuxfoundation.org/tc-docs/certification/important-instructions-cks`
- `https://docs.linuxfoundation.org/tc-docs/certification/certification-resources-allowed`
