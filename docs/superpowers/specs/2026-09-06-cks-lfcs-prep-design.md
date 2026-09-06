# CKS + LFCS Preparation Kit — Design Spec

**Date:** 2026-09-06
**Status:** Design approved in brainstorm; spec pending owner review
**Owner:** Sanjeev Murthy (CKA and CKAD passed; CKS and LFCS vouchers expire March 2027)
**Repo:** `le-kubernetes` (LFCS material lives here under `lfcs/`, mirroring `cks/`)
**Evidence base:** `docs/research/2026-09-06-cks-exam-research.md`, `docs/research/2026-09-06-lfcs-exam-research.md`, `docs/research/2026-09-06-repo-and-le-linux-analysis.md`

---

## 1. Goals and non-goals

### Goals

1. A one-stop kit to pass **CKS** (target exam Sat 12 Dec 2026) and then **LFCS** (target exam Sat 6 Feb 2027) before both vouchers expire in March 2027.
2. For each exam: study notes in exam-task-recipe style, a real-exam task compilation with frequencies, a practice CLI with automated setup/verify/cleanup per question, timed mock exams scored by the CLI, cheatsheets, an Anki deck, a dated study plan, and an exam-day playbook.
3. Repair the existing `cks/` material (June 2026) rather than rewrite it: fix broken verifiers, make node-level setups real, deepen the three 20%-weight notes, re-date the plan.
4. Every document verified for relative links, anchors, TOCs, mermaid syntax, and shell syntax before a phase is called done.

### Non-goals

- No refactor of the CKA and CKAD practice CLIs beyond fixing the two CKA v2 verifiers that share the compact-JSON grep bug.
- No renaming of legacy files that violate the naming convention (tracked separately as optional hygiene).
- No KCNA, KCSA, or other certification content.
- No cloud infrastructure; all labs run on Killercoda, KodeKloud sandboxes, minikube, or local VirtualBox VMs.
- No x86 emulation; VMs are arm64 and the notes call out where the exam's amd64 hosts differ.

---

## 2. Verified exam facts the kit must reflect

All facts below were fetched from Linux Foundation pages on 2026-09-06 (see research reports for URLs). Re-check the two "Important Instructions" pages the week before each booking.

### CKS

| Fact | Value |
|---|---|
| Exam environment | Kubernetes **v1.35** (curriculum document v1.34; text unchanged since April 2025) |
| Format | 15 to 20 performance tasks (candidates consistently report 16), 2 hours, pass mark 67% |
| Domains | Cluster Setup 15%, Cluster Hardening 15%, System Hardening 10%, Minimize Microservice Vulnerabilities 20%, Supply Chain Security 20%, Monitoring Logging and Runtime Security 20% |
| Allowed docs | kubernetes.io/docs and /blog, falco.org/docs, kubernetes-sigs.github.io/bom, etcd.io/docs, ingress-nginx user guide, docs.cilium.io, istio.io/latest/docs, plus task Quick Reference links. **Not allowed:** Trivy, kube-bench, AppArmor, kubesec docs |
| Task hosts | `ssh <node>` from `base`; `sudo -i`; `k` alias with completion, `yq`, `curl`, `wget`, `man`. **No `jq`.** No bookmarks; one monitor; INSERT key disabled in vim |
| Retake and validity | One free retake within 12 months of purchase; certification valid 2 years; per the LF blog of June 2026, passing CKS on or after 18 Jun 2026 also extends the CKA under CARE |
| Simulator | Two killer.sh sessions of 17 different questions each, 36 h per activation |

### LFCS

| Fact | Value |
|---|---|
| Curriculum | Five-domain distribution-agnostic curriculum in force since 11 May 2023; no change announced |
| Format | 17 to 20 performance tasks, 2 hours, pass mark 67% |
| Domains | Operations Deployment 25%, Networking 25%, Storage 20%, Essential Commands 20%, Users and Groups 10% (34 sub-bullets, quoted verbatim in the LFCS research report §1.2) |
| Allowed docs | Man pages, `/usr/share` docs, and distribution packages reachable from the terminal. **No browser documentation** |
| Environment | `base` host must not be rebooted; each task on a designated host via `ssh <nodename>`; nested SSH unsupported; `sudo -i`; hosts have vim, nano, emacs, git, sudo; never block ports 8080, 4505, 4506 |
| Distribution | Not stated officially. Candidates report Ubuntu primarily, possibly CentOS-family nodes; SELinux is an explicit bullet. Kit targets Ubuntu 24.04 first and Rocky 9 second |
| Retake and validity | One free retake within 12 months of purchase; valid 2 years |
| Simulator | Two killer.sh sessions, identical 20 questions, 36 h each |

---

## 3. Owner parameters

| Parameter | Value |
|---|---|
| Study start | Last week of September 2026 |
| Capacity | About 6 h per week on weekends (3 + 3) through October; 10 to 12 h per week in November and December; assume 8 to 10 h per week in January |
| CKS status | Not started; new to AppArmor, seccomp, Falco, Trivy, admission policies, audit logs |
| Paid resources | KodeKloud subscription; killer.sh sessions included with both vouchers |
| Labs | Killercoda, KodeKloud sandboxes, minikube on the Mac for CKS; VirtualBox VMs on the Mac for LFCS |
| Mac | Apple Silicon, 24 GB RAM, 12 cores, about 26 GB free disk; Docker Desktop installed but stopped; bash 3.2; no `timeout`; active kubectl context is a work AKS cluster |
| Style | Exam-task recipes; TOC on every note; mermaid only where a flow needs it; Anki decks in the le-linux tab format |
| Git | Branch `cks` for phases 0 to 2, branch `lfcs` for phases 3 to 5, PR at the end of each phase |

---

## 4. Repository layout

```
le-kubernetes/
├── README.md                          # updated: CKS active, LFCS added, current focus
├── CLAUDE.md                          # updated: cks/, lfcs/, practice-cli contract, scripts/
├── roadmap.md                         # NEW combined calendar Sept 2026 to Mar 2027
├── docs/
│   ├── research/                      # NEW the three 2026-09-06 research reports
│   └── superpowers/{specs,plans}/     # NEW this spec and the implementation plan
├── scripts/                           # NEW repo-wide tooling
│   ├── check-docs.sh                  # links, anchors, TOC, mermaid, bash -n
│   ├── check-links.py
│   ├── generate_toc.py                # ported from le-linux, adds --check
│   └── check-mermaid.sh
├── cks/
│   ├── README.md                      # refreshed facts, how to use, folder map
│   ├── lab-setup/                     # NEW minikube+Calico, Killercoda usage, optional kubeadm single node
│   ├── study-plan/                    # re-dated: README, 00-calendar, 01-domain-checklists, 02-resources, 03-exam-day-playbook
│   ├── study-notes/                   # 00-exam-environment (new), 01..06 upgraded
│   ├── cheatsheets/                   # NEW cks-exam-cheatsheet.md, cks-anki-deck.txt
│   ├── practice-tests/exam-questions/ # NEW cks-real-exam-questions.md
│   ├── mock-exams/                    # NEW mock-1..3.md papers + mock-1..3.set
│   └── practice-cli/                  # upgraded (see §7)
└── lfcs/                              # NEW, same shape
    ├── README.md
    ├── lab-setup/                     # VirtualBox guide, provision scripts, VM specs
    ├── study-plan/
    ├── study-notes/                   # 00-exam-environment, 01-operations-deployment, 02-networking,
    │                                  # 03-storage, 04-essential-commands, 05-users-and-groups, 06-linux-basics-refresher
    ├── cheatsheets/                   # lfcs-exam-cheatsheet.md, man-page-navigation.md, lfcs-anki-deck.txt
    ├── practice-tests/exam-questions/ # lfcs-real-exam-questions.md
    ├── mock-exams/
    └── practice-cli/
```

`le-linux` stays untouched and is referenced by GitHub URL from the LFCS notes where its storage, kernel, and networking sections add depth.

---

## 5. Study calendar

Weekend-anchored, dated. Both exams should be booked as soon as the plan is approved so the dates are real.

| Phase | Dates | Pace | Content |
|---|---|---|---|
| CKS foundation | Sat 26 Sep to Sun 1 Nov | 6 h/wk | One domain per weekend in curriculum order, System Hardening and Runtime Security front-loaded; KodeKloud CKS lessons mapped to each note; kubectl-level CLI questions on minikube; Killercoda scenarios for node-level topics; Anki daily |
| CKS drills | Mon 2 Nov to Sun 29 Nov | 10 to 12 h/wk | Every CLI question timed and interleaved; node-level questions on Killercoda; KodeKloud mock 1 to 3; repo mocks on Sat 14 Nov and Sat 21 Nov; apiserver crash-recovery drill weekly; killer.sh session 1 on Sat 28 Nov with gap review on Sun 29 Nov |
| CKS simulation | Mon 30 Nov to Sat 12 Dec | 10 to 12 h/wk | Weak-area drills from session 1; repo mock 3 on Sat 5 Dec; killer.sh session 2 on Wed 9 Dec; exam Sat 12 Dec |
| LFCS lab and foundation | Sun 13 Dec to Sun 10 Jan | 10 to 12 h/wk | VM build on 13 Dec; KodeKloud LFCS course mapped to the five domain notes; CLI questions per domain; Rocky flavour for SELinux, firewalld, nmcli; repo mock 1 as a baseline on Sun 10 Jan |
| LFCS drills | Mon 11 Jan to Sun 31 Jan | 8 to 10 h/wk | All questions timed on both distros; KodeKloud mocks; repo mock 2 on Sat 16 Jan; killer.sh session 1 on Sat 23 Jan; two-host and persistence drills; repo mock 3 on Sun 31 Jan |
| LFCS simulation | Mon 1 Feb to Sat 6 Feb | as available | Weak-area drills; killer.sh session 2 on Wed 3 Feb; exam Sat 6 Feb 2027 |
| Buffer | 7 Feb to voucher expiry | | Retake window for either exam |

Study principles carried over from the June plan: active recall, spaced repetition via Anki, interleaving in the drill phase, hand-typing commands in the foundation phase, timed practice with a per-task cap, no multi-day gaps. Budget: CKS about 90 h, LFCS about 70 h.

If the CKS exam slips into January, the LFCS phases shift by the same amount; the last safe LFCS date is two weeks before the voucher expiry to keep a retake possible.

---

## 6. Lab environments

### CKS tier 1: minikube on the Mac

- Profile `cks`, two nodes, Docker driver, `--cni=calico` so NetworkPolicy is enforced, Kubernetes 1.35 or newer.
- Covers roughly 55% of the question bank: RBAC, ServiceAccounts, NetworkPolicy, PSA, SecurityContext, immutability, Trivy and static analysis, Ingress TLS, Kyverno and Gatekeeper, CSR, secrets handling.
- `cks/lab-setup/README.md` documents profile creation, ingress-nginx enablement, Kyverno or Gatekeeper install, and teardown.

### CKS tier 2: Killercoda and KodeKloud

- Killercoda "Killer Shell CKS" playground provides a kubeadm cluster with root; sessions are one hour, so node-level questions must set up in under a minute and solve in under eight.
- `cks/practice-cli/tools/install-tools.sh` installs, when missing: Falco (modern eBPF driver), Trivy, kube-bench, gVisor runsc with containerd runtime config, kubesec, bom, AppArmor utilities. Architecture-aware (amd64 and arm64).
- Covers: AppArmor, seccomp, Falco, kube-bench remediation, apiserver and kubelet flags, audit logging, encryption at rest and etcdctl, gVisor, kubeadm upgrade, strace, binary verification, Linux host hardening.
- Optional later: `lfcs/lab-setup/kubeadm-single-node.sh` turns the LFCS Ubuntu VM into a single-node kubeadm cluster for offline node-level practice.

### LFCS: VirtualBox on Apple Silicon

| VM | Image | Resources | Extras |
|---|---|---|---|
| `lfcs-ubuntu` | Ubuntu 24.04 LTS arm64 server | 2 vCPU, 4 GB, 25 GB root | three 2 GB spare disks, NAT plus host-only NIC, snapshot `clean` |
| `lfcs-rocky` | Rocky 9 arm64 minimal | 2 vCPU, 2 GB, 12 GB root | two 2 GB spare disks, same NICs, snapshot `clean` |

- Total disk about 45 GB; `lab-setup/README.md` starts with a Mac disk-space checklist (old minikube profiles and Docker images are the usual reclaim).
- `provision-ubuntu.sh` and `provision-rocky.sh` install the exam tool set: lvm2, mdadm, nfs server and client, autofs, podman, libvirt client and qemu, chrony, git, openssl, sysstat, nftables and iptables, ufw or firewalld, openldap client, quota tools, cryptsetup.
- Host `ssh node1` and `ssh node2` aliases mirror the exam's `ssh <nodename>` habit; the practice CLI runs inside the VM.
- Fallback if VirtualBox arm64 guests misbehave: UTM with the same images and the same scripts.

### Safety

- The CKS CLI refuses to run unless the current context matches an allow-list (`minikube`, `cks*`, `kubernetes-admin@kubernetes`, Killercoda defaults) or `CKS_ALLOW_CONTEXT=1` is set. Contexts whose names contain `aks`, `eks`, `gke`, or `prod` are always refused.
- The LFCS CLI refuses to run outside a VM marker file `/etc/lfcs-lab` written by the provision scripts, and requires root.

---

## 7. Practice CLI design

Both CLIs keep the CKAD harness (`colors.sh`, `menu.sh`, `progress.sh`, timer, registry helpers) and change the question contract.

### Menu

`[1]` list questions with domain, difficulty, needs, done mark; `[2]` select; `[3]` random incomplete; `[4]` progress by domain; `[5]` mock exam; `[E]` environment check; `[Q]` quit. Inside a question: `[S]` setup, `[Q]` question, `[H]` solution, `[V]` verify, `[C]` cleanup, `[B]` back.

### Per-question folder

```
questions/q07-apparmor-profile/
├── meta          # bash-sourceable key=value
├── question.md   # shown by [Q]; exam-style wording, exact names, paths, deliverables
├── solution.md   # shown by [H]; step-by-step, commands, why, verification, docs
├── setup.sh
├── verify.sh
└── cleanup.sh
```

`meta` fields: `id`, `title`, `domain`, `domain_short`, `difficulty`, `needs`, `weight`, `minutes`, `sources` (count of candidate reports), `tags`.

`tools/build-registry.sh` generates `lib/questions.sh` from the meta files so parallel authors never edit a shared file. `tools/build-guide.sh` concatenates question and solution files into `<cert>-exam-qa-guide.md` with a TOC and an exam-frequency column, for reading outside the CLI.

### Needs tags

| Tag | Meaning |
|---|---|
| `kubectl` | any cluster with a usable context |
| `cni-netpol` | NetworkPolicy-enforcing CNI (Calico or Cilium) |
| `ingress` | ingress-nginx present |
| `admission:kyverno` / `admission:gatekeeper` | policy engine installed |
| `node-root` | root shell on the control plane or a named worker |
| `tool:<name>` | falco, trivy, kube-bench, runsc, kubesec, bom, apparmor, strace |
| `disk` | at least one spare block device or loop-device support (LFCS) |
| `netns` | second host simulated with a network namespace peer (LFCS) |
| `host2` | a second VM required (LFCS; few questions) |
| `rocky` | must run on the Rocky VM (LFCS SELinux, firewalld, nmcli, dnf) |

`[E]` detects the environment and prints which questions are runnable now.

### Script contracts

- **setup.sh**: idempotent; prints scenario facts (namespaces, files, device names) and never hides them; exits non-zero with a clear message when a need is unmet; backs up every file it modifies under the state directory (`~/.cks-practice/backup/qNN/` or `/var/lib/lfcs/backup/qNN/`); node-level CKS setups create the real starting state (unloaded AppArmor profile file, seccomp JSON, misconfigured flag, partial audit policy).
- **verify.sh**: sources `lib/checks.sh`; one `PASS:` or `FAIL:` line per check with expected versus actual; `Results: N passed, M failed`; non-zero exit on any failure; tests the effect rather than the text (`kubectl auth can-i`, `curl -k` through the Ingress, `aa-status`, audit-log growth, `k8s:enc:` prefix via etcdctl, pod actually Running; LFCS `findmnt --verify`, `systemctl is-enabled` and `is-active`, `nft -j`, `getfacl`, `getent`, `chage -l`, `sshd -T`, `ip -j`); never changes state; at least one live-effect and one persistence check per LFCS task; uses `-o jsonpath`, `-o json` with `yq`, or `--noheadings` output, never greps for compact JSON.
- **cleanup.sh**: removes created resources, restores backups, detaches loop devices, deletes network namespaces, and polls apiserver health after restoring a static pod manifest.
- **lib/checks.sh**: `check`, `check_eq`, `check_contains`, `check_file_has`, `check_cmd_ok`, `check_pod_running`, `summary`.
- **lib/env.sh** (LFCS): `make_loop_disk`, `free_loop_disk`, `make_netns_peer` with veth pair and optional sshd, nfs, or http service inside it, `backup_file`, `restore_file`, `require_root`, `require_distro`.
- **lib/env.sh** (CKS): `require_context_allowed`, `detect_cni`, `require_node_root`, `require_tool`, `backup_manifest`, `wait_apiserver`.

### Mock mode

- `mock-exams/mock-N.set` lists question IDs with weights; `mock-exams/mock-N.md` is the printable paper with the same tasks, weights, and a per-task host or context line.
- `[5]` selects a set, runs all setups, starts one 120-minute timer, shows the task list with flag marks, and at the end runs every verifier, prints score as weighted percentage and per-domain breakdown, writes `~/.cks-practice/mock-results.log`, and offers cleanup.
- CKS mocks: 16 tasks each. LFCS mocks: 18 tasks each. Three per exam.

### Compatibility

- Menu and lib code stay bash 3.2 compatible (no `${var^^}`, no associative arrays, no `mapfile`) so the CLI can be smoke-tested on the Mac with `--list` and `--env`.
- Question scripts run on Linux with bash 5 and may use bash 4 features.
- State files `.timer`, `.progress`, and mock logs move out of the repo tree into the state directory; `.gitignore` gains `.timer` and `.progress` for the legacy CLIs.

### Repair list for the existing 18 CKS questions

| Question | Repair |
|---|---|
| Q1, Q14, Q15, Q18 | replace compact-JSON greps with jsonpath checks |
| Q2, Q6, Q7, Q8, Q12, Q14, Q16, Q17 | real setups: seed the misconfiguration or profile file; verifiers test effect and restart behaviour; cleanups restore backups |
| Q5 | create the `legacy` pod the question refers to |
| Q13 | require a Trivy scan output file as a deliverable |
| Q16 | tighten the rule check and add a reload plus alert-line check |
| Q1, Q3, Q13, Q18 | unique namespaces so cleanups do not collide |
| all | migrate to per-question files; add `meta`; keep the same IDs so the existing guide maps cleanly |

CKA v2 `q17` and `q18` get the same jsonpath fix in Phase 0.

---

## 8. Question banks

Built in priority order so the first thirty of each bank are the highest-yield tasks.

### CKS (target 44)

| Family | Count | Existing | Notes |
|---|---|---|---|
| Falco rule, output format, crictl mapping | 3 | Q16 | most-reported task; one question edits output fields and reads the log |
| Audit policy and apiserver wiring | 3 | Q17 | includes a forensics question on an existing log |
| ImagePolicyWebhook | 2 | Q14 | one with a deliberately broken kubeconfig `server:` |
| kube-bench, kubelet config, etcd and apiserver TLS | 3 | Q2 | |
| AppArmor | 2 | Q7 | profile name versus filename trap |
| seccomp | 2 | Q8 | Localhost profile and RuntimeDefault |
| NetworkPolicy incl. DNS egress, metadata block, Cilium policy | 4 | Q1 | |
| RBAC, ServiceAccounts, anonymous bindings | 3 | Q4, Q5 | |
| gVisor RuntimeClass | 2 | Q12 | dmesg deliverable |
| apiserver flags and crash recovery | 3 | Q6 | three break-and-recover variants |
| Secrets encryption, re-encrypt, etcdctl read | 3 | Q10 | |
| Trivy, Dockerfile and manifest analysis, kubesec, SBOM | 4 | Q13, Q15 | |
| Ingress TLS | 1 | Q3 | |
| Pod Security Admission | 2 | Q9 | |
| Immutability | 1 | Q18 | |
| kubeadm upgrade | 1 | | Killercoda or VM only |
| CSR and user certificates | 1 | | |
| Linux host hardening: users, services, ports, modules, packages | 2 | | |
| strace syscall investigation | 1 | | |
| Istio PeerAuthentication or Cilium encryption | 1 | | |

### LFCS (target 45)

| Domain | Weight | Count | Families |
|---|---|---|---|
| Operations Deployment | 25% | 11 | sysctl persistent, processes and pidstat, cron and at and timers, packages and repos, boot target and rescue and fsck, libvirt define and autostart, podman with limits and restart, SELinux on Rocky, systemd unit authoring, journald |
| Networking | 25% | 11 | netplan and nmcli static IP, static routes, hostname and resolver, chrony, ss and troubleshooting, sshd Match and keys, iptables and nftables persistence, port redirect and NAT, bridge, bonding, reverse proxy with nginx or haproxy |
| Storage | 20% | 9 | partition and format and fstab by UUID, LVM create, LVM extend online, swap file, NFS export and mount, NBD, autofs, RAID 1, quotas and disk-full triage, LUKS |
| Essential Commands | 20% | 9 | git basics, service troubleshooting, find with permissions and exec, text processing pipelines, archives, redirection in scripts, links and attributes, OpenSSL inspect and self-signed, resource monitoring |
| Users and Groups | 10% | 5 | user with UID shell home expiry, groups and sudoers, password ageing and pwquality, ACLs and SUID SGID sticky, ulimits and profiles, LDAP client |

Every LFCS question has an Ubuntu path; questions tagged `rocky` run on the Rocky VM; questions with distro-specific commands show both in the solution.

---

## 9. Notes, cheatsheets, and compilations

### Recipe note template

```
# <Cert> Study Notes — <Domain> (<weight>%)
<!-- toc --> … <!-- toc stop -->
## What the exam asks           task archetypes, frequency from research, links to CLI questions
## Recipe 1: <task>             Goal · Commands · Verify · Gotchas · Docs (allowed page or man page)
## Recipe N …
## Ubuntu vs Rocky              (LFCS only) side-by-side command table
## Quick reference              one screen of commands and paths
## Memorise                     items with no in-exam documentation
```

One mermaid diagram per note at most, only for a flow: admission chain, audit pipeline, LVM stack, boot and targets, netfilter hooks.

### CKS note changes

- New `00-exam-environment.md`: verified facts, hosts, tools, allowed docs, remote desktop rules.
- `01` to `03`: add TOC, recipes for the uncovered topics (metadata policy, binary checksums, CSR, upgrade, host hardening, capabilities).
- `04` to `06`: expand to full recipes for Gatekeeper template and constraint, Cilium and Istio encryption, Cosign verify, bom and kubesec output, Falco output format and reload and crictl mapping, audit-log forensics, behavioural analysis phases.

### LFCS notes

Seven files as listed in §4. `06-linux-basics-refresher.md` covers the implicit basics candidates still report: permissions, find, grep sed awk, archives, redirection, man navigation.

### Cheatsheets and Anki

- `cks-exam-cheatsheet.md`: aliases and vim setup, doc page titles to search, and the memorise list for Trivy, kube-bench, AppArmor, kubesec, crictl, etcdctl, yq.
- `lfcs-exam-cheatsheet.md` and `man-page-navigation.md`: whole-exam command list, `man -k`, `apropos`, section numbers, `/usr/share/doc` examples.
- Anki decks: `#separator:tab`, `#html:true`, `#tags column:3`, deck names `CKS` and `LFCS`; about 120 cards each, generated from the Memorise sections.

### Real-exam compilations

`<cert>-real-exam-questions.md`: per domain, a table of task type, frequency with source count, phrasing as remembered, starting state, gotchas, and the CLI question that drills it; a dated source list with URLs. Derived from the research reports.

### Study plans and playbooks

`study-plan/README.md` (parameters, phases, principles), `00-calendar.md` (weekend-by-weekend dated schedule with checkboxes), `01-domain-checklists.md` (every curriculum bullet, mastery state), `02-resources.md` (KodeKloud lesson to note mapping, Killercoda scenario map, allowed docs, page titles), `03-exam-day-playbook.md` (environment rules, first-two-minute setup, ordering, verification list, recovery procedures).

`roadmap.md` at the root combines both plans with booking dates, killer.sh dates, mock dates, and the retake window.

---

## 10. Verification tooling

`scripts/check-docs.sh` runs on every phase end and before every PR:

1. `check-links.py`: every relative link and image resolves; every `#anchor` matches a heading slug; external links listed, not fetched.
2. `generate_toc.py --check`: TOC blocks match headings; `--write` regenerates.
3. `check-mermaid.sh`: extracts fenced mermaid blocks and renders each with `npx -y @mermaid-js/mermaid-cli`; falls back to a syntax lint (known diagram type, balanced brackets, no tabs) when the renderer is unavailable.
4. `bash -n` on every `.sh` file and CLI entrypoint; `shellcheck` when installed.
5. Exit non-zero on any finding; prints a summary table.

Acceptance per phase also includes a coverage check: every curriculum bullet maps to at least one note recipe and one CLI question, recorded in `01-domain-checklists.md`.

Node-level verifiers cannot execute on the Mac. Each CLI phase ends with an owner smoke test on Killercoda or in the VM; failures are fixed before the phase PR is merged.

---

## 11. Repo hygiene in scope

- `.gitignore`: add `.timer`, `.progress`, `*.set.results`.
- Fix CKA v2 `q17` and `q18` verifiers.
- Root `README.md`: CKS active, LFCS added, structure tree, quick starts for both CLIs, verification script.
- `CLAUDE.md`: document `cks/`, `lfcs/`, the per-question CLI contract, `scripts/`, and the phase workflow.
- Out of scope, listed for later: untracking the four committed PDFs, renaming legacy files, moving the SSH key pair out of the working tree.

---

## 12. Build phases and agent strategy

| Phase | Branch | Done by | Deliverables | Acceptance |
|---|---|---|---|---|
| 0 | `cks` | 8 Sep | this spec, implementation plan, `docs/research/`, `.gitignore`, six verifier fixes, `scripts/` skeleton | `check-docs.sh` runs clean on the repo |
| 1 | `cks` | 20 Sep | CKS README, dated plan (5 files), notes 00 to 06, cheatsheet, Anki, real-exam compilation, lab-setup | links, TOC, mermaid clean; every bullet mapped to a recipe |
| 2a | `cks` | 26 Sep | CLI lib upgrade, registry and guide generators, 18 questions migrated and repaired, first 12 new high-frequency questions, tools installer | `bash -n` clean; `--list` and `--env` run on the Mac; owner smoke test on Killercoda |
| 2b | `cks` | 24 Oct | remaining questions in batches of five, mock mode, three mock papers and sets, PR | owner runs mock 1 end to end |
| 3 | `lfcs` | 15 Nov | LFCS README, lab-setup guide and scripts, plan, notes 00 to 06, cheatsheets, Anki, compilation | owner builds the VMs from the guide |
| 4 | `lfcs` | 12 Dec | LFCS CLI lib, questions in batches of five, three mocks, PR | owner smoke test in the VM |
| 5 | `lfcs` | 13 Dec | roadmap, root README, CLAUDE.md, final `check-docs.sh`, PR | all checks clean |

Agent strategy, from the limits observed in this environment:

- At most three subagents in parallel. Each owns exactly one file or one batch of five questions.
- Agents return content inline; the main session writes the files, runs the checks, and commits. Subagents cannot write to the scratchpad here and stalled on large writes in June 2026.
- Web research agents that hit the session rate limit are resumed with a message rather than relaunched.
- Every file group is committed as soon as it passes `check-docs.sh`, so a context reset never loses more than one group.

---

## 13. Risks and mitigations

| Risk | Mitigation |
|---|---|
| Mac disk space (26 GB free) blocks the VMs | Disk checklist first; VM sizes kept minimal; Rocky VM optional until Phase 4 |
| VirtualBox arm64 guests unstable | UTM fallback with identical images and scripts |
| Exam Kubernetes version moves to 1.36 or 1.37 | No curriculum item is version-sensitive; re-check the FAQ before booking |
| Killercoda one-hour sessions | Node-level setups under one minute; questions capped at eight minutes; installer caches nothing it cannot fetch in time |
| Falco on Killercoda kernels | Use the modern eBPF driver; question falls back to `falco --list` and rule-syntax checks if the driver cannot load |
| libvirt inside a VirtualBox VM without nested virtualization | Practice `virsh` define, autostart, and `virt-install --virt-type qemu` with a tiny image |
| LDAP client task needs a server | Containerised OpenLDAP inside the netns peer |
| Verifier correctness without local execution | Effect-based checks, `bash -n`, shellcheck, owner smoke tests as phase gates |
| Time slips | Banks built in priority order; the first thirty questions per exam are the pass-critical set |

---

## 14. Open items

1. Exact voucher expiry dates for CKS and LFCS (owner to confirm from the training portal).
2. KodeKloud CKS lab cluster version at the time of study (labs lagged the exam in 2025).
3. Whether the CKS voucher was bought under a scheme that excludes killer.sh; the portal's "Exam Simulator" button confirms.
