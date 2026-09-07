# CKS Calendar — 26 Sep to 12 Dec 2026

Twelve weekends from the first study day to exam day. Open this file each Saturday, do the block, tick the boxes.

**Legend:** 🎥 KodeKloud lesson · 📓 note in [`../study-notes/`](../study-notes/) · 🧪 practice CLI question · 🌐 Killercoda scenario · 📇 Anki · ⏱️ timed, target 8 minutes per task · ⚠️ needs a node root shell (Killercoda or KodeKloud lab, not minikube)

**Pace.** Weekdays are 15 minutes of Anki, nothing more. Weekends carry the work: 3 hours Saturday and 3 hours Sunday through 1 Nov, rising to 10 to 12 hours a week from 9 Nov. Total is about 90 hours.

**Two lab tiers.** Tier 1 is minikube with Calico on the Mac and covers every kubectl-level question. Tier 2 is the Killercoda Killer Shell CKS playground, which gives a kubeadm cluster with root and covers everything marked ⚠️. Build both before day one: [`../lab-setup/README.md`](../lab-setup/README.md).

**The single rule that decides the outcome.** Every question is run against a stopwatch. Anything over 8 minutes goes on the drill list and is repeated the following weekend. Failing candidates ran out of time; they did not lack knowledge.

---

<!-- toc -->
## Table of Contents

- [Phase 0 — before Saturday 26 September](#phase-0--before-saturday-26-september)
- [Phase 1 — Foundation (26 Sep to 8 Nov)](#phase-1--foundation-26-sep-to-8-nov)
  - [Weekend 1 — 26 to 27 Sep · Exam environment and Cluster Setup](#weekend-1--26-to-27-sep--exam-environment-and-cluster-setup)
  - [Weekend 2 — 3 to 4 Oct · Monitoring, Logging and Runtime Security (20%)](#weekend-2--3-to-4-oct--monitoring-logging-and-runtime-security-20)
  - [Weekend 3 — 10 to 11 Oct · Cluster Hardening (15%)](#weekend-3--10-to-11-oct--cluster-hardening-15)
  - [Weekend 4 — 17 to 18 Oct · System Hardening (10%)](#weekend-4--17-to-18-oct--system-hardening-10)
  - [Weekend 5 — 24 to 25 Oct · Minimize Microservice Vulnerabilities (20%)](#weekend-5--24-to-25-oct--minimize-microservice-vulnerabilities-20)
  - [Weekend 6 — 31 Oct to 1 Nov · Supply Chain Security (20%)](#weekend-6--31-oct-to-1-nov--supply-chain-security-20)
  - [Weekend 7 — 7 to 8 Nov · Foundation close-out](#weekend-7--7-to-8-nov--foundation-close-out)
- [Phase 2 — Drills (9 to 29 Nov, 10 to 12 hours a week)](#phase-2--drills-9-to-29-nov-10-to-12-hours-a-week)
  - [Week of 9 to 15 Nov](#week-of-9-to-15-nov)
  - [Week of 16 to 22 Nov](#week-of-16-to-22-nov)
  - [Week of 23 to 29 Nov](#week-of-23-to-29-nov)
- [Phase 3 — Simulation (30 Nov to 12 Dec)](#phase-3--simulation-30-nov-to-12-dec)
  - [Week of 30 Nov to 6 Dec](#week-of-30-nov-to-6-dec)
  - [Exam week, 7 to 12 Dec](#exam-week-7-to-12-dec)
- [After the exam](#after-the-exam)
- [If the date slips](#if-the-date-slips)

<!-- toc stop -->

## Phase 0 — before Saturday 26 September

- [ ] **Book the CKS exam for Saturday 12 December 2026.** Not yet booked. Booking releases the two killer.sh sessions this calendar schedules on 28 November and 9 December, and creates the deadline the rest of the plan depends on.
- [ ] Voucher expiry is confirmed: **3 March 2027**. A December attempt leaves eleven retake Saturdays, so there is no deadline pressure on CKS.
- [ ] Confirm the portal shows an **Exam Simulator** button. If it does not, the voucher may exclude killer.sh and the plan needs a paid session instead.
- [ ] Build tier 1 and tier 2 labs: [`../lab-setup/README.md`](../lab-setup/README.md).
- [ ] Import [`../cheatsheets/cks-anki-deck.txt`](../cheatsheets/cks-anki-deck.txt) into Anki. Set new cards to 15 per day.
- [ ] Read [`../study-notes/00-exam-environment.md`](../study-notes/00-exam-environment.md) end to end. It is the only note that is pure facts, and knowing them removes surprises on the day.
- [ ] Enrol in the KodeKloud CKS course and confirm the lab environment loads.

---

## Phase 1 — Foundation (26 Sep to 8 Nov)

Cover all six domains hands-on, building the Anki deck as you go. Runtime Security and System Hardening come early because they are the least familiar and carry 30 percent of the exam between them. Type every command; no copy and paste this phase.

### Weekend 1 — 26 to 27 Sep · Exam environment and Cluster Setup

- [ ] 📓 `00-exam-environment.md` (re-read), then `01-cluster-setup.md` recipes 1, 2, 3 and 6
- [ ] 🎥 KodeKloud: Cluster Setup section
- [ ] 🧪 Q1 NetworkPolicy default-deny, Q3 Ingress TLS, Q24 metadata endpoint (tier 1)
- [ ] 🌐 Killercoda: NetworkPolicy Create Default Deny, NetworkPolicy Metadata Protection, Ingress Secure
- [ ] 📇 New cards: policy skeleton, `podSelector` vs `namespaceSelector` vs `ipBlock`, the DNS egress rule, `kubectl create secret tls`
- [ ] Sunday close-out: close everything and re-type the default-deny plus DNS-allow pair from memory

### Weekend 2 — 3 to 4 Oct · Monitoring, Logging and Runtime Security (20%)

- [ ] 📓 `06-monitoring-logging-runtime.md` recipes 1 to 5
- [ ] 🎥 KodeKloud: Monitoring, Logging and Runtime Security section
- [ ] 🧪 ⚠️ Q16 Falco rule, Q19 Falco output format, Q17 audit policy, Q20 audit forensics
- [ ] 🌐 Killercoda: Falco Change Rule, Auditing Enable Audit Logging
- [ ] 📇 New cards: Falco file paths, the output fields, the reload signal, the five audit flags, the four audit levels
- [ ] Sunday close-out: write an audit policy from memory that logs secrets at RequestResponse and everything else at Metadata

### Weekend 3 — 10 to 11 Oct · Cluster Hardening (15%)

- [ ] 📓 `02-cluster-hardening.md` all seven recipes
- [ ] 🎥 KodeKloud: Cluster Hardening section
- [ ] 🧪 Q4 RBAC, Q5 ServiceAccount token, Q29 anonymous bindings (tier 1); ⚠️ Q6 apiserver flags, Q23 crash recovery
- [ ] 🌐 Killercoda: RBAC User Permissions, RBAC ServiceAccount Permissions, Apiserver Crash, Apiserver NodeRestriction
- [ ] 📇 New cards: `auth can-i --as` syntax, the SA subject form, the apiserver recovery sequence
- [ ] Sunday close-out: break the apiserver deliberately three ways and recover each without notes

### Weekend 4 — 17 to 18 Oct · System Hardening (10%)

- [ ] 📓 `03-system-hardening.md` all seven recipes
- [ ] 🎥 KodeKloud: System Hardening section
- [ ] 🧪 ⚠️ Q7 AppArmor, Q34 AppArmor name trap, Q8 seccomp, Q30 seccomp deny, Q41 rogue service, Q42 users and modules
- [ ] 🌐 Killercoda: AppArmor, System Hardening Close Open Ports, System Hardening Manage Packages
- [ ] 📇 New cards: profile name versus file name, `apparmor_parser -q`, `aa-status`, the seccomp directory, `SCMP_ACT_ERRNO`
- [ ] Sunday close-out: load a profile and confine a pod with no documentation open

### Weekend 5 — 24 to 25 Oct · Minimize Microservice Vulnerabilities (20%)

- [ ] 📓 `04-microservice-vulnerabilities.md` all nine recipes
- [ ] 🎥 KodeKloud: Microservice Vulnerabilities section
- [ ] 🧪 Q9 Pod Security Admission, Q11 Kyverno, Q36 PSA violators (tier 1); ⚠️ Q10 encryption at rest, Q12 gVisor, Q25 etcd secret, Q26 re-encrypt, Q28 gVisor dmesg
- [ ] 🌐 Killercoda: Secret ETCD Encryption, Sandbox gVisor, Secret Read and Decode
- [ ] 📇 New cards: PSA label keys, the restricted checklist, the etcdctl command with its three certificate flags, `k8s:enc:aescbc`, the `runsc` handler
- [ ] Sunday close-out: encrypt secrets at rest and prove it from etcd, from memory

### Weekend 6 — 31 Oct to 1 Nov · Supply Chain Security (20%)

- [ ] 📓 `05-supply-chain-security.md` all eight recipes
- [ ] 🎥 KodeKloud: Supply Chain Security section
- [ ] 🧪 Q13 Trivy, Q15 static analysis, Q27 Dockerfile and manifest (tier 1); ⚠️ Q14 ImagePolicyWebhook, Q21 broken webhook kubeconfig, Q38 SBOM
- [ ] 🌐 Killercoda: Image Vulnerability Scanning Trivy, Static Manual Analysis Docker, Static Manual Analysis K8s, Image Use Digest
- [ ] 📇 New cards: Trivy severity flags, `kubesec scan`, `bom generate`, the three ImagePolicyWebhook pieces
- [ ] Sunday close-out: wire ImagePolicyWebhook end to end and prove a pod is denied

### Weekend 7 — 7 to 8 Nov · Foundation close-out

- [ ] 📓 `01-cluster-setup.md` recipes 4, 5 and 7 (kube-bench, TLS ciphers, binary checksums)
- [ ] 🧪 ⚠️ Q2 kube-bench, Q22 kubelet CIS, Q33 TLS ciphers, Q39 kubeadm upgrade, Q40 CSR, Q43 strace
- [ ] 🧪 Q35 Cilium L7 policy and Q44 Istio mTLS if a Cilium or Istio playground is available; otherwise read the recipes and make cards
- [ ] 🌐 Killercoda: CIS Benchmarks fix Controlplane, Verify Platform Binaries, CertificateSigningRequests sign via API, Syscall Activity Strace
- [ ] **Re-score every line of [`01-domain-checklists.md`](01-domain-checklists.md).** Anything still `[ ]` is the drill list for the next three weeks.
- [ ] Sunday close-out: read the score. If more than a quarter of the lines are still `[ ]`, spend the first drill week on those rather than on mocks.

---

## Phase 2 — Drills (9 to 29 Nov, 10 to 12 hours a week)

Never do two consecutive questions from the same domain. Interleaving is what teaches the discrimination the exam demands, such as AppArmor versus seccomp versus gVisor.

### Week of 9 to 15 Nov

- [ ] ⏱️ Every tier-1 question in random order, 8 minute cap, twice through the week
- [ ] ⏱️ ⚠️ Every node-level question once on Killercoda
- [ ] 🎥 KodeKloud mock exam 1, then review every miss
- [ ] **Saturday 14 Nov: repo mock 1** (`./cks --mock 1`, 120 minutes, no notes). Record the score in [`../mock-exams/README.md`](../mock-exams/README.md).
- [ ] Drill list from mock 1 on Sunday

### Week of 16 to 22 Nov

- [ ] ⏱️ Weak-area loop from mock 1
- [ ] 🎥 KodeKloud mock exam 2
- [ ] Apiserver crash-recovery drill: three different breakages, recovered under 5 minutes each
- [ ] **Saturday 21 Nov: repo mock 2.** Target 75 percent or better.
- [ ] Drill list from mock 2 on Sunday

### Week of 23 to 29 Nov

- [ ] 🎥 KodeKloud mock exam 3
- [ ] ⏱️ Every question whose best time is still over 8 minutes
- [ ] **Saturday 28 Nov: killer.sh session 1.** Expect a low score; it is harder than the real exam by design. The 36 hours of access start when you activate it.
- [ ] **Sunday 29 Nov: review killer.sh session 1 in full.** Every question you missed becomes an Anki card and a drill-list entry.

---

## Phase 3 — Simulation (30 Nov to 12 Dec)

### Week of 30 Nov to 6 Dec

- [ ] ⏱️ Drill every gap from killer.sh session 1 until each is under 8 minutes
- [ ] Re-score [`01-domain-checklists.md`](01-domain-checklists.md). Target: nearly every line `[x]`.
- [ ] **Saturday 5 Dec: repo mock 3.** Target 85 percent or better.
- [ ] Sunday: read [`03-exam-day-playbook.md`](03-exam-day-playbook.md) end to end and rehearse the first two minutes on a task host

### Exam week, 7 to 12 Dec

- [ ] Mon and Tue: Anki only, plus one timed question a day from the weakest domain
- [ ] **Wednesday 9 Dec: killer.sh session 2.** Different questions from session 1. Aim to finish comfortably.
- [ ] Thursday: review session 2 misses only
- [ ] Friday: no new material. Re-read the playbook and the cheatsheet. Confirm the PSI system check passes on the machine you will use. Sleep.
- [ ] **Saturday 12 December: exam.** Join 30 minutes early. Scan every task first, do the confident ones, flag anything past 10 minutes, keep the last 15 minutes for verification.

---

## After the exam

- [ ] Results arrive by email within 24 hours. Passing CKS also extends the CKA under the CARE policy.
- [ ] If it did not pass: reschedule the free retake immediately, while the environment is fresh. Eight of the 28 candidate write-ups in the research failed once and every one of them passed on the retake, usually with a large jump.
- [ ] Either way, LFCS study starts Sunday 13 December, on the calendar at `lfcs/study-plan/00-calendar.md`.

---

## If the date slips

The plan compresses and stretches at known points.

| Situation | What to change |
|---|---|
| Two weeks behind at 8 Nov | Move the exam to 9 Jan. Keep every weekend as written and add the missed material to the drill weeks. |
| Cannot get 10 to 12 hours a week in November | Drop KodeKloud mocks 2 and 3, keep both repo mocks and both killer.sh sessions. The mocks are the highest-yield hours. |
| Exam moves later than mid-January | Shift the LFCS calendar by the same amount and check the LFCS voucher expiry has room for a retake. |
| A domain is still weak at 5 Dec | Move the exam by two weeks rather than sitting it. The free retake is worth more as insurance than as a first attempt. |
