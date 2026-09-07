# Local Repository Analysis: le-kubernetes (CKS) and le-linux (LFCS)

Produced by the repo-analysis agent on 2026-09-06 (returned inline; saved here by the orchestrator). Scope: local-only reading of `/Users/sanjeevmurthy/le/repos/le-kubernetes` and `/Users/sanjeevmurthy/le/repos/le-linux`. No files were modified. Every claim was checked by reading the files or running read-only commands (`find`, `wc`, `grep`, `git log`, `git ls-files`, `bash -n`, and one `kubectl --dry-run=client` that never contacts a cluster).

## Summary

**CKS coverage headline**: 40 curriculum sub-topics tracked (the `cks/README.md` list plus three official items it omits). All 40 have some note coverage (17 worked examples, 16 commands-level, 7 mention-only); 23 are exercised by at least one of the 18 CLI questions; 17 have no practice question. All CKS content was committed on one day (2026-06-08) and untouched since. Zero mermaid diagrams, zero TOCs, all 37 internal links resolve.

**Top 5 CKS gaps**
1. Four verifiers can never pass (Q1 all 3 checks, Q14 Kyverno path, Q15, Q18): they grep compact JSON (`"app":"backend"`) but `kubectl -o json` is pretty-printed (`"app": "backend"`), confirmed locally with `--dry-run=client`. CKA v2 q17/q18 have the same bug.
2. Eight of 18 setups are echo-only (Q2, Q6, Q7, Q8, Q12, Q14, Q16, Q17) and the CLI discards setup output, so the instructions are never shown; six verifiers only grep node files and need root on the control plane.
3. 17 sub-topics have no question: metadata-endpoint NetworkPolicy, binary checksums, dashboard RBAC, CSR, kubeadm upgrade, node services/ports/modules/users/UFW, capabilities, Dockerfile hardening, SBOM, Cosign, Falco output-edit+reload, audit-log forensics, Gatekeeper.
4. The 20%-weight notes (04, 05, 06) are the shortest (146–190 lines); Gatekeeper, mTLS, Cosign, behavioral analytics are mention-only. No mock exams, no Anki deck.
5. Plan is undated and pins v1.34; it ignores the March 2027 voucher deadline recorded in `todo-cks-lfcs.md`. CLI lacks CKAD's progress/random mode and reintroduces a bash-4-only construct.

**Top 5 LFCS gaps in le-linux** (52-row matrix: 15 reusable, 17 partial, 20 gap)
1. Users & Groups almost entirely absent: zero `useradd/usermod/chage/login.defs/profile` hits; sudoers only mentioned.
2. Operations: no systemd unit authoring or timers, no cron/at, no package management, no shell scripting, no git, no podman workflow, no virsh.
3. Storage persistence: fstab mentioned once, no mkswap/swapon, quotas, or LUKS setup (LVM/partitioning/mdadm are excellent).
4. Networking setup side: no nmcli/netplan persistence, no firewalld/ufw, NFS covered only as troubleshooting, chrony only in an incident.
5. Essential commands: archives, redirection, man pages, environment, and a systematic find/grep/sed/awk section are missing; the repo is interview/internals oriented (115k words, 79 mermaid diagrams, 229 interview questions, no exercises).

**LFCS CLI recommendation**: Clone the CKA/CKAD harness (colors, menu, progress, registry helpers, timer; about 300 lines) but change the contract: run as root inside a disposable VM (`EUID` guard), create block devices from sparse files via `losetup` and a network-namespace peer for NFS/SSH/firewall tasks in a shared `lib/env.sh`, back up every touched file and restore it in cleanup, replace the monolithic guide with per-question `question.md`/`solution.md`/`meta` files, keep setup output visible, and verify with machine-readable state commands (`getent`, `getfacl`, `lsblk -no`, `lvs --noheadings`, `findmnt -no`, `findmnt --verify`, `systemctl is-enabled/is-active`, `ss -H`, `nft -j`, `sshd -T`, `ip -j`) checking both live effect and persistence. Add a mock mode with an exam-length global timer, which none of the existing CLIs has.

---

## A. le-kubernetes inventory

### A.1 Directory table

Counts are on-disk (excluding `.git`); "tracked" is from `git ls-files`. Line counts exclude PDF/zip/binary files.

| Directory | Files on disk | Lines | Tracked | Notes |
|---|---|---|---|---|
| `.` (root) | 441 | 53,807 | 422 | Root files: `.gitignore`, `CLAUDE.md`, `README.md` (tracked); `dropbox.sh`, `dropbox.zip`, `todo-cks-lfcs.md`, `todo-cks-studyplan.md`, `.DS_Store` (ignored) |
| `.claude/` | 4 | 62 | 0 | Ignored. `settings.local.json` (permission allow-list) + `projects/.../memory/` (3 memory notes about CKS prep) |
| `cka/` | 254 | 39,525 | 251 | |
| `cka/cheatsheets/` | 3 | 3,094 | 3 | `cka-exam-cheatsheet.md` (1,230), `kubectl-imperative-commands.md` (1,193), `exam-readiness.md` (671) |
| `cka/course-notes/` | 38 | 1,543 | 38 | Udemy YAMLs + shell histories (`history.sh`, `cmd_history.sh`) |
| `cka/practice-cli/` | 133 | 8,649 | 133 | `v1/` (17 q) and `v2/` (22 q) |
| `cka/practice-tests/` | 17 | 19,774 | 17 | `udemy/` (6 md), `killercoda/` (2 md, 1 py, 1 PDF), `exam-questions/` (6 md, 1 html) |
| `cka/resources/` | 2 | 0 | 2 | Two PDFs |
| `cka/study-guide/` | 57 | 3,689 | 55 | 4 domain folders; `tls.crt`/`tls.key` on disk but ignored |
| `cka/troubleshooting/` | 2 | 2,723 | 2 | `troubleshooting-scenarios.md` + a 9 MB PDF |
| `ckad/` | 87 | 9,402 | 85 | |
| `ckad/course-notes/` | 1 | 37 | 1 | `1-core-commands.sh` (a shell history) |
| `ckad/practice-cli/` | 82 | 7,119 | 82 | 24 questions + `ckad-exam-qa-guide.md` (1,953), `ckad-cheetsheet.md` (989), `ckad-trevor.md` (839), `comparison-result.md` (299) |
| `ckad/practice-tests/` | 2 | 2,183 | 1 | `killercoda/simulator-claude.md`; `Killrcoda simulator.pdf` untracked |
| `cks/` | 74 | 4,224 | 74 | See Section B |
| `cks/practice-cli/` | 61 | 2,030 | 61 | 18 questions, `cks` (346), `cks-exam-qa-guide.md` (859), `lib/` (4 files) |
| `cks/study-notes/` | 7 | 1,486 | 7 | 6 notes + README |
| `cks/study-plan/` | 5 | 653 | 5 | README + 00..03 |
| `k8s-cluster-keys/` | 2 | 50 | 0 | Ignored; contains an SSH private/public key pair on disk |
| `kcna/` | 1 | 25 | 1 | README placeholder |
| `kcsa/` | 1 | 27 | 1 | README placeholder |
| `minikube/` | 1 | 37 | 0 | Ignored setup script |
| `shared/` | 7 | 184 | 7 | `cluster-setup/minikube-commands.sh`, 6 manifests |
| `x-prompt/` | 2 | 31 | 0 | Ignored prompts (`ckad-cli.md`, `x-todo-shared.md`) |

### A.2 git history for `cks/`

```
4d27c2d 2026-06-08 update cks README
79baa2a 2026-06-08 add study plan
3dc69f4 2026-06-08 add cks study notes
c0eb5d4 2026-06-08 add cks practice cli
8f9c2ab 2026-03-06 restructure repo for Kubestronaut certification preparation
```

All CKS content was committed on a single day (2026-06-08, about three months ago) and has not been touched since. The repo's last commit overall is `cf14f21 2026-06-08 Merge pull request #3 ... ckad`. Working tree is clean.

### A.3 `.gitignore`, `.claude/`, and oddities

`.gitignore` ignores: OS files, editors, `k8s-cluster-keys/`, `*.key`, `*.crt`, `*.pem`, `*.kubeconfig`, `kubeconfig`, `.claude/`, `*.pdf`, `dropbox.sh`, `dropbox.zip`, `minikube/`, `x-prompt/`, `*todo*.md`.

1. **Four PDFs are tracked despite `*.pdf`** (rule added after they were committed): `cka/practice-tests/killercoda/Simulator 2.pdf`, `cka/resources/CKA-Study-Guide.pdf`, `cka/resources/Cluster Architecture, Installation & Configuration.pdf`, `cka/troubleshooting/Certified Kubernetes Administrator Study Companion.pdf` (9 MB).
2. **`.claude/` inside the repo** (ignored) holds `settings.local.json` with an allow-list of WebFetch domains (medium.com, devopscube.com, itexams.com, kodekloud notes) and Bash permissions, plus three memory files: `MEMORY.md`, `cks-prep-context.md` (records: CKA passed, 15 days at 2 h/day then 1 h/day, KodeKloud + killer.sh, beginner at security tooling, deliverables built), and `agent-background-stalls-on-large-writes.md` (notes this Mac has bash 3.2 and no `timeout`).
3. **Runtime state files `.timer` and `.progress`** written by the CLIs into their own directories are neither tracked nor ignored.
4. **Secrets on disk**: `k8s-cluster-keys/k8s_cluster_key` (mode 600) and `cka/study-guide/3-services-and-networking/GatewayAPI/tls.key` exist in the working tree. Both are ignored and never committed (`git log --all` confirms).
5. **Stale docs**: root `README.md` lists CKS as "Planned"/"placeholder" and CKAD as "In Progress"; the structure tree omits `cks/` subfolders. `CLAUDE.md` mentions only `cka/practice-cli/`. `cka/practice-cli/v1/README.md` quick start says `cd CKA/tests/lfcs-questions/cka-cli-tool` (pre-restructure path).
6. **Naming convention violations** (CLAUDE.md wants lowercase-with-hyphens): `Part 2 50 Questions.md`, `Simulator 2.pdf`, `Exam_topics_Questions.md`, `GatewayAPI/`, `Killrcoda simulator.pdf`, and the typo `ckad-cheetsheet.md`.
7. `cka/practice-cli/v2/` has no README (v1 does).
8. `ckad/practice-cli/comparison-result.md` and `x-prompt/ckad-cli.md` reference a third repo (`le-cert-prep/cert-prep/ckad/08_Probable_Questions.md`) not analyzed here.
9. `todo-cks-lfcs.md` (ignored) is the owner's brief and adds a constraint the CKS plan does not know: **both exam vouchers expire in March 2027**.

---

## B. CKS content assessment

### B.1 Study plan (`cks/study-plan/`, 653 lines, ~6,100 words)

| File | Lines | Content |
|---|---|---|
| `README.md` | 64 | Parameters table, three phases, six study principles (active recall, spaced repetition, interleaving, generation effect, timed deliberate practice, momentum), daily ritual template, how-to-use |
| `00-daily-schedule.md` | 173 | Phase 0 setup checklist; Day 1–45 day-by-day; "if your timeline changes" (compress to 30 / extend to 60 days) |
| `01-domain-checklists.md` | 127 | Per-domain `[ ]/[~]/[x]` checklists (9+10+7+10+9+9 = 54 items), 24-row master tool checklist, 8 file paths |
| `02-resources.md` | 107 | Tiered resources (KodeKloud, killer.sh, killercoda, GitHub sets), practice-cluster advice (2-node kubeadm; table of what cannot run on kind), allowed doc domains, 14 kubernetes.io pages, exam facts |
| `03-exam-day-playbook.md` | 182 | Aliases/`.vimrc`, context-switch rule, three-pass strategy, safe apiserver edit, gotchas, PSI do's/don'ts, top-15 lessons, command cheats |

Phases: **Foundation** Days 1–15 at 2 h/day, **Consolidation** Days 16–35 at 1 h/day (mocks Days 21/28/35), **Simulation** Days 36–45 at 1 h/day (killer.sh Days 38 and 44, exam Day 45). Assumptions: CKA passed; beginner with security tooling; 60 study hours; KodeKloud; killer.sh sessions. The plan is **relative, not dated** ("Day 1 … Day 45", "book the exam ~45 days out"). It pins Kubernetes **v1.34** "as of this writing" (June 2026), which needs re-verification today. No mention of LFCS or the March 2027 deadline.

### B.2 Study notes (`cks/study-notes/`, 1,486 lines, ~7,800 words)

| Note | Lines / words | H2 headings | TOC | Mermaid | Internal links | External links | K8s version |
|---|---|---|---|---|---|---|---|
| `01-cluster-setup.md` | 403 / 1,950 | NetworkPolicy default-deny; DNS egress trap; blocking metadata endpoint; CIS & kube-bench; Ingress TLS; verifying binaries; minimizing dashboard exposure; quick reference; docs | No | 0 | none | 9 (kubernetes.io ×5, kube-bench, cisecurity, dl.k8s.io ×2) | v1.34, v1.34.0 |
| `02-cluster-hardening.md` | 184 / 1,054 | RBAC least privilege; SA token hardening; restrict API server; NodeRestriction & keeping current; quick ref; docs | No | 0 | none | 7 (kubernetes.io) | v1.34, v1.34.x |
| `03-system-hardening.md` | 377 / 1,830 | Reduce host OS footprint; restrict kernel modules; least-privilege identity & SSH (UFW); AppArmor; seccomp; capabilities; securityContext pod vs container; quick ref; docs | No | 0 | none | 4 (kubernetes.io) | v1.34; "1.30+" for `appArmorProfile` |
| `04-microservice-vulnerabilities.md` | 190 / 975 | PSA/PSS; Gatekeeper & Kyverno; secrets encryption at rest; RuntimeClass/gVisor; mTLS & immutable; quick ref; docs | No | 0 | none | 8 | v1.34 |
| `05-supply-chain-security.md` | 161 / 880 | Minimize base image; Trivy; kubesec & kube-linter; SBOM; restrict images (ImagePolicyWebhook, Kyverno, Cosign); quick ref; docs | No | 0 | none | 7 | v1.34 |
| `06-monitoring-logging-runtime.md` | 146 / 903 | Falco; audit logging; behavioral analytics; immutable containers; quick ref; docs | No | 0 | none | 6 | v1.34 |
| `README.md` | 25 / 253 | Reading order mapping notes to Q1–3, Q4–6, Q7–8, Q9–12, Q13–15, Q16–18 | No | 0 | 8, all resolve | 0 | v1.34 |

Verified: **zero mermaid diagrams and zero TOC markers under `cks/`**; **all 37 relative links resolve**. External links (86 unique) were listed, not fetched. Every note uses the same template (What the examiner tests / Why it matters / Concepts / Commands & examples / Exam tips / Quick reference / Docs). Notes 04–06 (the 60%-weight trio per the README) are the shortest.

### B.3 Coverage matrix

Rows are the `cks/README.md` "Key Topics" sub-topics plus three official items it omits (†). Depth: none / mention / commands / worked example.

| Domain | Sub-topic | Note | Depth | CLI question(s) |
|---|---|---|---|---|
| D1 Cluster Setup 15% | NetworkPolicy default-deny + selective allow | 01 | worked example | Q1 |
| D1 | DNS egress (port 53 UDP+TCP) under deny-all | 01 | worked example | Q1 (check 3) |
| D1 | Node metadata endpoint protection (`ipBlock` + `except`) | 01 | worked example | none |
| D1 | CIS benchmark / kube-bench | 01 | commands | Q2 |
| D1 | Ingress TLS | 01 | worked example | Q3 |
| D1 | Verify platform binaries (sha256/sha512) | 01 | commands | none |
| D1 | Minimize GUI/dashboard exposure † | 01 | commands | none |
| D2 Cluster Hardening 15% | RBAC least privilege + `auth can-i` | 02 | worked example | Q4 |
| D2 | ServiceAccount token controls | 02 | worked example | Q5 |
| D2 | API-server flags + safe edit/recover | 02 | commands | Q6 |
| D2 | NodeRestriction | 02 | mention | Q6 (flag grep) |
| D2 | `kubeadm upgrade` / drain / uncordon | 02 | commands (6 lines) | none |
| D2 | CSR approve/deny | 02 | commands (3 lines) | none |
| D3 System Hardening 10% | Host OS footprint (services, packages, ports) | 03 | commands | none |
| D3 | Kernel module blacklisting | 03 | commands | none |
| D3 | OS identity / SSH / sudo / UFW † | 03 | commands | none |
| D3 | AppArmor | 03 | worked example | Q7 |
| D3 | seccomp | 03 | worked example | Q8 |
| D3 | Linux capabilities | 03 | worked example | none directly (Q15 checks `drop: ALL`) |
| D3 | securityContext pod vs container | 03 | commands + table | Q15, Q18 indirectly |
| D4 Microservice Vulns 20% | Pod Security Admission/Standards | 04 | worked example | Q9 |
| D4 | OPA Gatekeeper | 04 | mention (sketch, no Rego) | Q11 verifies Kyverno only |
| D4 | Kyverno ClusterPolicy | 04 | worked example | Q11 |
| D4 | Secrets encryption at rest | 04 | worked example | Q10 |
| D4 | RuntimeClass / gVisor | 04 | worked example | Q12 |
| D4 | Pod-to-pod mTLS (Cilium/Istio) | 04 | mention | none |
| D4 | Secrets management practices † | 04 | mention | none |
| D4 | Immutable containers | 04, 06 | commands | Q18 |
| D5 Supply Chain 20% | Minimal base images / multi-stage Dockerfile | 05 | worked example | none |
| D5 | Trivy | 05 | commands | Q13 |
| D5 | kubesec / kube-linter | 05 | commands | Q15 |
| D5 | SBOM (`bom`, `syft`) | 05 | commands | none |
| D5 | Cosign | 05 | mention | none |
| D5 | ImagePolicyWebhook | 05 | commands (sketch) | Q14 option B |
| D5 | Allowed-registry admission (Kyverno) | 05 | worked example | Q11, Q14 option A |
| D6 Monitoring/Runtime 20% | Falco custom rule | 06 | worked example | Q16 |
| D6 | Falco reload, output-format change, log parsing | 06 | commands | Q16 does not check these |
| D6 | Audit policy + apiserver flags + mounts | 06 | worked example | Q17 |
| D6 | Behavioral analytics / attack phases | 06 | mention | none |
| D6 | Container immutability at runtime | 06 | commands | Q18 |

Headline: **40 sub-topics; 40/40 have note coverage (17 worked examples, 16 commands, 7 mention-only); 23/40 have a CLI question; 17/40 have none.**

### B.4 Practice CLI (`cks/practice-cli/`)

A clone of `cka/practice-cli/v2` with registry, guide and questions swapped: `cks` (346 lines), `lib/colors.sh` (identical), `lib/menu.sh` (identical except title/column width), `lib/questions.sh` (18 entries, D1–D6 colors), `lib/setup_map.sh` (identical), `cks-exam-qa-guide.md` (18 archetypes: `### Qn.` / `**Question:**` / `**Concept & Explanation:**` / `**Solution — Step by Step:**` / `**Key Points to Remember:**` / `**Official Documentation:**`). `bash -n` passes on every script; executable bits set.

| Q | Domain | Setup does | Verify checks | Quality | Needs |
|---|---|---|---|---|---|
| 1 | D1 | ns `prod`, deployments `backend` (port 8080), `frontend` | greps `-o json` for policyTypes, `"podSelector":{}`, `"app":"backend"`, `"port":8080`, `"port":53` | **Broken** (bug 1): 3/3 checks can never pass; no connectivity probe | kubectl; NP-capable CNI (unchecked) |
| 2 | D1 | echo only | grep `--anonymous-auth=false` in apiserver manifest; `readOnlyPort: 0` in kubelet config | File-grep; never runs kube-bench; no health check; no cleanup | root on control plane |
| 3 | D1 | ns `prod`, deploy + svc `web` | secret type, `spec.tls[0].secretName`, host | OK (jsonpath); no TLS test | kubectl |
| 4 | D2 | ns `build`, SA `ci`, CRB → cluster-admin | five `auth can-i --as` checks | **Good** | kubectl |
| 5 | D2 | ns `app` only | SA automount false; pod `legacy` uses SA; no token | OK, but question says pod `legacy` exists; setup never creates it | kubectl |
| 6 | D2 | echo only | three flag greps in manifest | File-grep; no `/readyz`; no cleanup | root on control plane |
| 7 | D3 | echo only (profile "provided" but never created) | pod exists; field/annotation | Spec-only; no `aa-status`/enforcement test | node root |
| 8 | D3 | echo only | seccomp type/profile on two pods | Spec-only; passes even if pod cannot start | node root |
| 9 | D4 | ns `payments` | enforce label; privileged run rejected | **Good** (functional) | kubectl |
| 10 | D4 | secret `pre-existing` | flag grep; provider keyword in `enc.yaml` | File-grep; no etcd/re-encrypt check | root on control plane |
| 11 | D4 | warns if Kyverno absent | policy exists, `Enforce`, mentions `registry.internal` | OK; no functional test | kubectl + Kyverno |
| 12 | D4 | echo only | handler `runsc`; pod `runtimeClassName` | Spec-only; no Running check | gVisor node |
| 13 | D5 | ns `prod`, deploy nginx:1.18.0 | image changed and pinned; rollout ok | OK (trivy never required) | kubectl |
| 14 | D5 | echo + Kyverno check | Kyverno: compact-JSON grep (**broken**); webhook: manifest greps | Kyverno path never passes | kubectl / root |
| 15 | D5 | ns `appsec`, insecure deploy | RORF, APE, `"drop":["ALL"]` (**broken**), runAsNonRoot | 1/4 can never pass | kubectl |
| 16 | D6 | echo only | grep `proc.name`, `bash\|sh`, `priority: WARNING` in local rules | `grep -Eq 'bash|sh'` matches almost anything; no reload/alert check; no cleanup | root, Falco |
| 17 | D6 | echo only | audit flags; policy mentions `secrets` + `RequestResponse` | File-grep; no order/log/health check; no cleanup | root on control plane |
| 18 | D6 | ns `prod`, deploy `api` | RORF, APE, `"mountPath":"/tmp"` (**broken**) | 1/3 can never pass | kubectl |

Six verifiers read node files (`q02, q06, q10, q14, q16, q17`) and must run as root on the control plane; Q7/Q8/Q12 need node prep. **8 of 18 setups are echo-only.**

Bugs and assumptions:
1. **Compact-JSON grep (confirmed)**: `kubectl create namespace x --dry-run=client -o json` prints `"name": "x"`; the pattern `"name":"x"` matches 0 times. Breaks Q1 (3 checks), Q14 (Kyverno path), Q15, Q18, and CKA v2 `q17` (3 checks) and `q18`. CKAD avoids it via `-o jsonpath`.
2. `run_setup` runs `bash "$setup" > /dev/null 2>&1`, so echo-only setups print instructions nobody sees.
3. `case "${action^^}"` is bash-4-only (CKAD used `tr`); this Mac has only bash 3.2, `/opt/homebrew/bin/bash` is absent, so the CLI cannot be smoke-tested locally.
4. Q5 presupposes pod `legacy`; Q7 presupposes the AppArmor profile file.
5. Q1, Q3, Q13, Q18 share namespace `prod`; cleanups delete the namespace.
6. Assumed kubeadm paths, `/var/lib/kubelet/seccomp/profiles/`, `/etc/apparmor.d/`, `/etc/falco/`, `runsc`, Kyverno, NP-enforcing CNI. No node names hard-coded.
7. No cleanup for Q2, Q6, Q16, Q17; partial for Q10, Q14. `.timer` not gitignored.

Missing vs other CLIs: no progress file, per-domain progress, checkmarks, or random mode (CKAD `lib/progress.sh`); little expected-vs-actual output; no environment pre-flight; no mock mode (none of the CLIs has one). Timer thresholds 5/8 min vs 5/10 (intentional).

### B.5 Prioritized CKS gap list

1. Fix the four broken verifiers (Q1, Q14, Q15, Q18) with `-o jsonpath`/`jq`; fix CKA v2 q17/q18 too.
2. Make node-level questions real: setup creates the AppArmor profile, seccomp JSON, misconfigured apiserver/kubelet; verify tests effect (`aa-status`, `crictl inspect`, `/readyz`, audit log growth, `k8s:enc:` bytes); cleanup restores backups.
3. Add questions for the 17 uncovered sub-topics.
4. Deepen mention-only material in 04/05/06 (Gatekeeper template, mTLS, Cosign, behavioral analysis, secrets practices); note 06 is the shortest.
5. Strengthen weak verifiers (Q2/Q6/Q10/Q16/Q17 file-greps; Q8/Q12 pass on unstartable pods; Q13 ignores Trivy).
6. Build mock exams (none exist for CKS).
7. Fold in the March 2027 deadline and re-verify the exam version.
8. Add TOCs and diagrams to match the owner's le-linux style.

---

## C. Reference pattern from CKA and CKAD

### C.1 CLI architecture

- **Menu flow**: `main()` → `[1]` list, `[2]` select (padded `%02d`, `get_question_by_num`) → `question_loop` → `[S]` setup, `[Q]` question, `[H]` solution (confirm), `[V]` verify, `[C]` cleanup (confirm), `[B]` back. CKAD adds `[3]` random incomplete, `[4]` progress.
- **Registry**: `QUESTIONS=( "01|Title|Domain|D1|Medium|q01-folder" … )`; accessors via `cut -d'|'`; difficulty/domain color maps.
- **Contract**: `setup.sh` (idempotent, `set -e`, may pre-check tools and `exit 1`), `verify.sh` (`Checking …` then `  PASS:`/`  FAIL:` lines, counters, `Results: N passed, M failed`, `[[ $FAIL -eq 0 ]]`), `cleanup.sh` (`--ignore-not-found`, restore backups; `q20` restores the apiserver manifest and polls `kubectl get nodes` up to 60 s). Setup/cleanup output discarded; verify output shown.
- **Timer**: epoch in `$SCRIPT_DIR/.timer`; start on setup, stop on passing verify; pace feedback; shown in header.
- **Progress (CKAD)**: `.progress` file of IDs; `is_complete`, `get_random_incomplete` (`$RANDOM`), `show_progress` bar + per-domain counts.
- **Solution display**: `extract_section` slices the markdown guide between `### Qn.` (CKA/CKS) or `### Question n.m ` (CKAD, via `get_guide_num` map) and the Solution / Key Points markers. `display_question_file` exists but is unused.
- **Colors**: `lib/colors.sh` (ANSI, box header, emoji icons, print helpers).
- **Dependencies**: bash 4+ (CKAD bash-3 safe), `kubectl` with context, per-question tools; no `jq`/`yq`.

| Feature | CKA v1 | CKA v2 | CKAD | CKS |
|---|---|---|---|---|
| Questions | 17 | 22 | 24 | 18 |
| Guide format | retake guide | `### Qn.` | `### Question n.m —` + `#### Question/Concept/Solution/Points to Remember/Official Documentation`, TOC, "Exam Frequency" | `### Qn.` |
| Progress/random | no | no | yes | no |
| Bash 3 safe | no | no | yes | no |
| README | yes (stale path) | no | `ckad/README.md` | yes |

### C.2 Document formats elsewhere

- **Real exam questions** (`cka/practice-tests/exam-questions/`): `cka-retake-questions-final.md` ("actual CKA exam questions reconstructed from memory and verified against online sources"; TOC by domain; "Exam Setup — Paste First"; exact wording → steps → imperative → YAML → verification → docs). `Exam_topics_Questions.md` records variants ("Question 1 & 21 (v1)"). `cka-1week-aggressive-plan-v2.md` is a retake plan from seven missed questions with "Confirmed by other exam takers". `Part 2 50 Questions.md` is a domain narrative plus 50-question bank. CKAD's guide lists 12 named candidate reports with dates and an "Exam Frequency (n sources)" column; `ckad-trevor.md` compares an external set (SIMILAR/PARTIALLY NEW/UNIQUE) and writes up unique ones as `Question T.n`; `comparison-result.md` is a V1-vs-V2 overlap analysis.
- **Simulator guides**: killer.sh PDFs parsed by `parse_simulator_v3.py` into `## Question N: title` → `### Context` → `### Solution` (`#### Step` blocks) → `### Tips & Troubleshooting`/`### Validation` → `### References`.
- **Course mocks** (`udemy/mockN-solutions.md`): `## Qn — title` → Question → Solution (options) → Validation → 📖 docs; `test3-failed.md` records failed questions with "Validation Criteria".
- **Study guide**: YAML manifests named after resources, a few markdown component guides with numbered sections and official links, shell histories.
- **Cheatsheets**: TOC, numbered `## n.` sections, fenced command blocks with inline comments, "Golden Pattern", gotchas; `exam-readiness.md` is a prose checklist.
- **Troubleshooting**: TOC table (`# | Component | Scenario`), methodology, 29 scenarios each `### Question / Diagnosis / Solution / Validation / 📖 Documentation`.

### C.3 What an LFCS practice CLI must change

1. **Privilege**: run inside a disposable Linux VM as root (`[[ $EUID -eq 0 ]] || exec sudo -E "$0" "$@"`).
2. **Verify with machine-readable commands, testing effect and persistence**: `id -u`, `getent passwd|group`, `chage -l`, `sudo -l -U`, `stat -c '%a %U:%G'`, `getfacl -p`, `lsattr`, `lsblk -no NAME,FSTYPE,MOUNTPOINT,UUID`, `blkid -o value -s TYPE`, `pvs/vgs/lvs --noheadings -o`, `findmnt -no OPTIONS,FSTYPE`, `findmnt --verify`, `swapon --show --noheadings`, `systemctl is-active/is-enabled/show -p`, `systemctl list-timers --no-legend`, `crontab -l -u`, `journalctl -o json`, `sysctl -n`, `modprobe --showconfig` + `lsmod`, `ip -j addr/route`, `resolvectl status`, `ss -H -ltn`, `nft -j list ruleset`/`firewall-cmd --list-all`, `sshd -T`, `exportfs -v`, `showmount -e`, `chronyc tracking`, `podman inspect --format`, `git log --oneline`. Avoid grepping human output where `-o`/`-j`/`--noheadings` exists.
3. **Block devices**: loop devices from sparse files (`fallocate -l 1G …; losetup -fP --show`) in `lib/env.sh`; optionally spare virtual disks.
4. **Second host**: a network-namespace peer (veth pair; run `sshd -f`, a tiny HTTP server, or NFS export inside it) for NFS/SSH/firewall/route tasks; fall back to a `host2` VM declared in an env file.
5. **Safety**: back up every touched file to `/var/lib/lfcs/backup/qNN/`, restore in cleanup; README says "snapshot the VM first"; `Needs` field (`none|disk|netns|host2|reboot`).
6. **Do not swallow setup output** (scenario facts such as the loop device name).
7. **Per-question files** (`question.md`, `solution.md`, `hints.md`, `meta`) instead of a monolithic guide.
8. **Mock mode**: N questions across domains, one exam-length global timer, verify all at the end, per-domain score.

Proposed layout (reuse `colors.sh`, `menu.sh`, `progress.sh`, `setup_map.sh`, timer and registry helpers; ~300 lines):

```
lfcs/practice-cli/
├── lfcs                      # root guard, env pre-flight, menus, mock mode
├── README.md                 # VM requirements, snapshot advice, distro notes
├── lib/
│   ├── colors.sh             # unchanged
│   ├── menu.sh               # unchanged + [M] mock, [E] env check
│   ├── progress.sh           # unchanged (domain list edited)
│   ├── questions.sh          # ID|Title|Domain|Dn|Difficulty|Folder|Needs
│   ├── env.sh                # make_loop_disk, free_loop_disk, make_netns_peer, backup_file, restore_file
│   └── checks.sh             # check_eq/check_cmd/check_file_contains → PASS/FAIL lines
└── questions/
    └── q01-lvm-extend/
        ├── meta              # needs=disk; timeout=8; distro=any
        ├── question.md       # [Q]
        ├── solution.md       # [H]
        ├── setup.sh          # sources ../../lib/env.sh; creates loop disks; backs up files
        ├── verify.sh         # sources ../../lib/checks.sh; exits non-zero on any FAIL
        └── cleanup.sh        # umount/lvremove/vgremove/pvremove/losetup -d; restore backups
```

Verify contract: same PASS/FAIL counters, one line per check, `Results:` summary, exit status; plus expected-vs-actual on each check; at least one effect and one persistence check per task where applicable; checks independent of the tool the student used; never change state. Home: `le-linux/lfcs/` (le-kubernetes' CLAUDE.md scopes that repo to CNCF exams).

---

## D. le-linux assessment for LFCS

### D.1 Inventory and orientation

| Path | Files | Lines | Tracked |
|---|---|---|---|
| `README.md` | 1 | 109 | yes |
| `x-prompt-initialize.md` | 1 | 271 | no (`*prompt*.md`) |
| `docs/superpowers/specs/…design.md` | 1 | 246 | yes |
| `docs/superpowers/plans/…knowledge-base.md` | 1 | 801 | yes |
| `linux-notes/00..11/*.md` (12 topic notes) | 12 | 15,893 (115,539 words) | yes |
| `linux-notes/cheatsheets/` | 15 | 3,889 | yes (incl. `linux-cheatsheet.md` 201, `linux-sre-anki-deck.txt` 108) |
| `linux-notes/interview-questions/` | 13 | 6,784 (229 questions) | yes |
| `scripts/` | 2 | 597 | yes (`extract_pdfs.py`, `generate_toc.py`) |
| `shell_scripts/` | 2 | 123 | yes (zsh history logger + ignore list) |
| `sources/` | 3 PDFs + 372 extracted | 131,514 | no (ignored) |
| `.superpowers/brainstorm/` | 5 | 185 | no |

Last commit `9dd3947 2026-09-06 docs: add linux cheatsheet and SRE anki deck` (today); clean tree.

Orientation: "Linux Interview Preparation Knowledge Base — Senior SRE / Staff / Principal (10+ years)", "No beginner explanations", 9-section template per topic (Concept, Internal Working, Commands, Debugging, 5 FAANG incidents, Interview Questions, Pitfalls, Pro Tips, Cheatsheet). Keyword sweep: `sysctl` 86 hits, `iptables` 66, `modprobe/lsmod` 52, `nice/renice/kill` 107, `PAM` 52, `auditd` 48; `useradd/usermod/userdel` 0, `chage/login.defs` 0, `/etc/profile|bashrc` 0, `OnCalendar|.timer` 0, `git` 1, `ufw` 0, `fstab` 1, `quota` only cgroup/k8s, `man` 1. No exercise/lab sections exist.

Formats the owner uses: TOC in every file (`<!-- toc -->` markers via `generate_toc.py`, PR #2); **79 mermaid diagrams** (67 in notes, 12 in cheatsheets: `graph` 35, `flowchart` 34, `sequenceDiagram` 7, `stateDiagram-v2` 3; two "fix mermaid" commits and PR #1; spec mandates "Mermaid exclusively"); zero image files/refs today despite commit messages mentioning images; heavy tables (84 rows in note 01, 111 in its cheatsheet); cheatsheets with TOC + at-a-glance diagram + fenced command blocks + decision tables; `linux-cheatsheet.md` "command + SRE Context" style; **Anki deck** in Anki text import format (`#separator:tab`, `#html:true`, `#tags column:3`, `#deck:Linux-SRE`, 104 `front<TAB>back<TAB>tag` rows, `<br>` breaks); interview files `### Qn.` with Senior/Staff/Principal tags. All relative links resolve (the one "MISSING → F" hit at `05-lvm/lvm.md:740` is a false positive from an `mdstat` line).

### D.2 LFCS mapping matrix

Coverage: concept / commands / exercise (none exist). Rating: Reusable / Partial / Gap.

| LFCS domain | Sub-topic | le-linux location | Coverage | Rating |
|---|---|---|---|---|
| Ops & Deployment 25% | Boot, GRUB, targets, rescue, initramfs | 00 §2–§4 (`systemd-analyze`, grub `e`, `rd.break`, `fsck.mode=skip`); anki #5–13 | concept + commands (deep) | Partial |
| | systemd unit authoring/enable/mask/drop-ins | 00 pro tips, 10 §3, anki #16; no `[Unit]/[Service]/[Install]` example | fragments | Gap |
| | systemd timers | none | — | Gap |
| | cron / at | 05, 09, anki #91 mentions | mention | Gap |
| | journalctl / rsyslog / logrotate | 00, 07, 10, 11, cheatsheets (journalctl only) | commands | Partial |
| | Package management | 09 (`rpm -Va`, `debsums`) | mention | Gap |
| | Kernel parameters (`sysctl`, `/etc/sysctl.d`) | 07 §3, 06 §9, 09 §9 | commands | Reusable |
| | Kernel modules | 07 §3 | commands | Reusable |
| | Process management | 01 §3, 02 §3, anki #17–24 | commands (deep) | Reusable |
| | Resource monitoring | 08 §3, cheatsheets README | commands | Reusable |
| | Shell scripting | none (`save_commands.sh` is zsh) | — | Gap |
| | git basics | none | — | Gap |
| | Containers (podman/docker) | 07 §3, 10 §3 mentions | mention | Gap |
| | Virtualization (virsh/KVM) | 10 §2 concept | concept | Gap |
| Networking 25% | IP config + persistence (nmcli/netplan) | 06 §3 (`ip` runtime only) | commands | Partial |
| | Routing | 06 §3, 07 §3 | commands | Partial |
| | DNS client | 06 §2–§3, 11, anki #65 | concept + commands | Reusable |
| | Firewall (firewalld/ufw/nft/iptables) | 09 §3, 06 §3 (nft/iptables only) | commands | Partial |
| | SSH | 09 §3, anki #88 | commands | Reusable |
| | NFS server/client, autofs | 01/02/04 troubleshooting only | concept | Gap |
| | Time sync | 11 incident 9 | commands (diagnosis) | Partial |
| | Ports/troubleshooting | 06 §3, cheatsheets, anki #62–63 | commands | Reusable |
| | Reverse proxy/LB basics (if on syllabus) | 06 incident 4 | mention | Gap |
| Storage 20% | Partitioning | 05 §3 | commands | Reusable |
| | LVM | 05 §3, cheatsheet 05, anki #54–58 | commands | Reusable |
| | Filesystems (mkfs/tune2fs/xfs/fsck/resize) | 04 §3, 05 | commands | Partial |
| | Mount + fstab | 04 §3; fstab once | commands | Partial |
| | Swap | 03, anki #38 | mention | Gap |
| | Quotas | none | — | Gap |
| | RAID | 05 §3 | commands | Reusable |
| | LUKS | 00 mentions | mention | Gap |
| | Disk usage/inodes | 04 §3, cheatsheets, anki #46/#50 | commands | Reusable |
| Essential Commands 20% | File ops, links | 04 §1, §3 | concept + commands | Partial |
| | Permissions/umask/SUID/SGID/sticky | 09 §2.3, §3, anki #87 | commands | Reusable |
| | ACLs | 09 §2.3, §3 | commands | Reusable |
| | find | scattered | commands | Partial |
| | grep/sed/awk text processing | scattered | commands | Partial |
| | Archives | 1 mention | — | Gap |
| | Redirection/pipes | implicit | — | Gap |
| | man/docs | 1 mention | — | Gap |
| | Shell environment | none | — | Gap |
| Users & Groups 10% | useradd/usermod/groups, passwd/shadow/group | none | — | Gap |
| | sudo/sudoers | 09 mentions | mention | Gap |
| | Password policy (chage/login.defs/pwquality) | 09 §3 (faillock, pwquality) | commands (partial) | Partial |
| | PAM | 09 §2.1, §3, anki #86 | concept + commands | Reusable |
| | Profiles/skel | none | — | Gap |
| | Resource limits | 09 §3, 01, anki #23 | commands | Partial |
| | LDAP/SSSD (if on syllabus) | none | — | Gap |

Tally (52 rows): **Reusable 15, Partial 17, Gap 20.** Strongest overlap: Storage and diagnostic Networking; weakest: Users & Groups and the "administer a box" half of Operations.

### D.3 Deeper than needed, zero coverage, and book chapters

Deeper than LFCS: every "Internal Working" section, all incident narratives, PSI/perf/bpftrace/ftrace/kdump (08), NUMA/THP, cgroup v2 (07), system design (10), SRE incidents (11). LFCS-useful residue: "3. Commands" and "9. Cheatsheet" of 04, 05, 06, 07, 09 plus boot triage in 00.

Zero/near-zero: systemd units/timers, cron/at, packages, scripting, git, podman, virsh, nmcli/netplan, firewalld/ufw, NFS setup, chrony config, swap, quotas, LUKS, mkfs/fstab recipes, archives, redirection, man, environment, user/group lifecycle, sudoers, chage/login.defs, profiles/skel.

Extracted chapters mapping (manifest: 371 files, 0 errors; text has layout artifacts):

| LFCS domain | ULSAH | How Linux Works | Linux Basics for Hackers |
|---|---|---|---|
| Ops & Deployment | ch18–ch28 booting/systemd (ch25 systemd in detail 423 lines, ch27, ch28); ch35–ch44 processes (ch44 periodic processes 424: cron, timers); ch52–ch59 packages (ch54–56); ch60–ch69 scripting (ch63 sh 348, ch64 regex 246, ch68 git 201); ch89–ch96 logging (ch91 journal, ch92 syslog 435, ch94 rotation); ch97–ch107 kernel (ch103 modules); ch231–ch239 virtualization (ch233 KVM, ch238 Vagrant); ch240–ch245 containers (ch242 Docker 550) | ch10–ch13 boot/init; ch14/15 system configuration (logging, time, cron, users; 1,623 lines); ch16/17 processes; ch22/23 shell scripts; ch34/35 virtualization | ch14 processes; ch16 bash scripting; ch19 logging; ch20 services; ch23 modules; ch24 job scheduling; ch12 software |
| Networking | ch113–ch129 TCP/IP (ch118 routing, ch122 basic config 260, ch123 Linux networking 323, ch125 troubleshooting 362, ch127 firewalls/NAT 288); ch140–ch148 routing; ch149–ch161 DNS (ch151); ch204–ch213 NFS (ch207 server 219, ch208 client 115, ch212 automount 236); ch253–ch266 security (ch260 SSH 377, ch261 firewalls 132) | ch18/19 network config; ch20/21 services; ch24/25 file transfer/sharing | ch11 networks; ch20 services; ch21 SSH/proxies |
| Storage | ch188–ch203 (ch189 add a disk, ch194 partitioning 197, ch195 LVM 195, ch196 RAID 289, ch197–198 filesystems 378); ch45–ch51 (ch47 mounting 108, ch50 attributes 349, ch51 ACLs 433) | ch06/07 devices; ch08/09 disks/filesystems/partitioning | ch18 filesystem/storage |
| Essential Commands | ch45–ch51; ch60–ch64; ch11 man pages | ch04 basic commands; ch05 Bourne shell; ch26/27 user environments | ch09 basics; ch10 text manipulation; ch13 permissions; ch15 env vars; ch17 archiving |
| Users & Groups | ch70–ch81 (ch72–75 passwd/shadow/group, ch76 manual steps 204, ch77 useradd 118, ch78 removal, ch79 lockout, ch80 PAM, ch81 centralized); ch29–ch34 access control/root (ch31 sudo) | ch14/15 users section | ch15 user environment |

ULSAH (2017) predates nftables/firewalld defaults, netplan, podman; the web research task should supply current-distro specifics.

---

## E. Recommendations

### E.1 CKS

**Keep**: the plan/notes/CLI structure and cross-links; `03-exam-day-playbook.md` and `01-domain-checklists.md`; the note template; Q4/Q9/Q13 as the verifier pattern.

**Extend**: notes 04–06 (complete Gatekeeper template, Cosign walk-through, Cilium/Istio mTLS example, Falco output-edit + reload + read sequence, audit-log forensics exercise, `bom` output); add TOCs (`generate_toc.py`) and a few mermaid diagrams; a dated plan ending before March 2027 that interleaves LFCS; re-verify exam version/allowed docs; port CKAD's `progress.sh` and bash-3-safe uppercasing; stop discarding setup output; gitignore `.timer`/`.progress`.

**Build new**: fix/rewrite the eight echo-only and four broken verifiers; ~12–15 questions for the 17 uncovered sub-topics; two or three CKS mock exams in the simulator-guide format plus a CLI mock mode with a 120-minute timer; a CKS Anki deck in the `linux-sre-anki-deck.txt` format.

### E.2 LFCS

**Reuse from le-linux**: commands sections of 05, 04, 06, 07, 09, 00 §4; cheatsheet and Anki formats; `generate_toc.py`; mermaid conventions; extracted chapters as sources.

**Build new** (priority order): (1) five LFCS-domain notes at task level covering the 20 Gap rows; (2) the LFCS CLI from C.3 with ~25 questions (users/groups/sudo/chage 5; systemd/timers/cron/journal 5; LVM/partitions/fstab/swap/quota/RAID/LUKS 7; network/routes/DNS/firewall/SSH/NFS/chrony 6; scripting/find/text/archives 2+); (3) two full-length mock exams and an LFCS Anki deck; (4) an exam-environment playbook mirroring `03-exam-day-playbook.md`, populated from web research.

### E.3 Repo hygiene

1. Untrack the four PDFs (or drop the `*.pdf` rule); keep binaries under `<cert>/resources/`.
2. Rename to lowercase-hyphen: `Part 2 50 Questions.md`, `Simulator 2.pdf`, `Exam_topics_Questions.md`, `GatewayAPI/`, `Killrcoda simulator.pdf`, `ckad-cheetsheet.md`.
3. Add `.timer`, `.progress` to `.gitignore`.
4. Update root `README.md` (CKS/CKAD status, structure), `CLAUDE.md` (mention `ckad/practice-cli`, `cks/`, future `lfcs/`), `cka/practice-cli/v1/README.md` (stale path).
5. Fix compact-JSON greps in CKA v2 `q17`/`q18` and the CKS ones.
6. Move the SSH key pair out of the working tree.
7. In le-linux: give LFCS its own top-level folder and README section; reconcile commit messages about images with the (image-less) tree.
8. Install bash 5 locally or make all CLIs bash-3 safe so they can be smoke-tested on this Mac; real verification still needs a Linux VM/cluster.
