# CKS Study Plan

A dated, weekend-anchored plan to go from CKA-certified to CKS-certified by **Saturday 12 December 2026**, built for someone new to the security tooling (AppArmor, seccomp, Falco, Trivy, admission policies, audit logs).

<!-- toc -->
## Table of Contents

- [Your parameters](#your-parameters)
- [The three phases](#the-three-phases)
- [What the exam actually is](#what-the-exam-actually-is)
- [The six principles this plan is built on](#the-six-principles-this-plan-is-built-on)
- [Weekend ritual](#weekend-ritual)
- [The five things that fail candidates](#the-five-things-that-fail-candidates)
- [The files here](#the-files-here)
- [Related](#related)

<!-- toc stop -->

## Your parameters

| | |
|--|--|
| CKA | Passed, so you are eligible to register today |
| CKS status | Not started as of September 2026 |
| Security-tooling level | Beginner, so Runtime Security and System Hardening are front-loaded |
| Study start | Saturday 26 September 2026 |
| Time budget | Weekdays 15 minutes of Anki. Weekends 3 hours plus 3 hours to 1 Nov, then 10 to 12 hours a week. About 90 hours total. |
| Anchor course | KodeKloud CKS, one section per foundation weekend |
| Daily reps | The practice CLI in [`../practice-cli/`](../practice-cli/) and the free Killercoda Killer Shell CKS scenarios |
| Final simulation | Two killer.sh sessions included with the voucher: 28 Nov and 9 Dec |
| Exam | Saturday 12 December 2026 |
| Voucher expiry | March 2027, which leaves the free retake and a January second attempt in reach |

**First action:** book the exam. It releases the killer.sh sessions and turns the calendar into a commitment.

## The three phases

| Phase | Dates | Pace | Goal |
|---|---|---|---|
| **1 Foundation** | 26 Sep to 8 Nov | 6 h/week, rising | Cover all six domains hands-on, one per weekend, building the Anki deck. Runtime Security and System Hardening come early. |
| **2 Drills** | 9 to 29 Nov | 10 to 12 h/week | Timed, interleaved repetition of every question. Three KodeKloud mocks, two repo mocks, killer.sh session 1. |
| **3 Simulation** | 30 Nov to 12 Dec | 10 to 12 h/week | Close the gaps killer.sh exposes, repo mock 3, killer.sh session 2, exam. |

Day-by-day: [`00-calendar.md`](00-calendar.md).

## What the exam actually is

Verified against Linux Foundation pages on 6 September 2026. Full detail in [`../study-notes/00-exam-environment.md`](../study-notes/00-exam-environment.md).

| | |
|--|--|
| Environment | Kubernetes **v1.35** (the published curriculum document is v1.34) |
| Format | 15 to 20 performance-based tasks, candidates consistently report 16. Two hours. |
| Pass mark | 67 percent, so roughly 11 of 16 tasks solved cleanly |
| Hosts | One designated host per task, reached with `ssh <nodename>` from `base`. No nested SSH. `sudo -i` for root. |
| Tools present | `kubectl` with a `k` alias and completion, `yq`, `curl`, `wget`, `man`. **No `jq`.** |
| Documentation | kubernetes.io docs and blog, falco.org, the bom CLI reference, etcd.io, the ingress-nginx user guide, docs.cilium.io, istio.io. **No Trivy, kube-bench, AppArmor or kubesec docs.** No bookmarks. |
| Retake | One free retake within 12 months of purchase |
| Bonus | Passing CKS on or after 18 June 2026 also extends the CKA under the CARE policy |

## The six principles this plan is built on

Each one is wired into the calendar; these are why the weekends look the way they do.

1. **Active recall over re-reading.** Every session ends by closing the notes and re-typing the commands from memory. Re-reading feels productive and is not.
2. **Spaced repetition.** Fifteen minutes of Anki every weekday, built from the `## Memorise` section of each note. The exam rewards exact paths and exact flags, which is precisely what spacing preserves.
3. **Interleaving.** In the drill phase, never two consecutive questions from the same domain. The exam demands you tell AppArmor, seccomp and gVisor apart under pressure; blocked practice hides that difficulty.
4. **Generation, not recognition.** Hand-type every command during the foundation phase. Copy and paste only to check a working answer.
5. **Timed deliberate practice.** Eight minutes per question, measured. Anything slower joins the drill list. Candidates fail on time, not on knowledge.
6. **Momentum.** CKS leans on short-term procedural memory. A short daily touch beats sporadic long sessions, which is why weekdays still carry the Anki block.

## Weekend ritual

```
[ 0:00 ] 20 min  Anki backlog, then read the day's note recipes
[ 0:20 ] 2 h     hands-on: practice CLI questions and Killercoda scenarios, each against a stopwatch
[ 2:20 ] 30 min  the hard one again, from memory, no notes open
[ 2:50 ] 10 min  turn every gap into an Anki card
```

## The five things that fail candidates

Taken from 28 first-hand write-ups in [`../../docs/research/2026-09-06-cks-exam-research.md`](../../docs/research/2026-09-06-cks-exam-research.md).

1. **Time.** Spending the first hour on three questions. Flag at 10 minutes and move.
2. **Weak Linux administration.** Users, groups, systemd and grep on large logs are assumed knowledge, not taught by the Kubernetes courses.
3. **Breaking the API server** while editing a static pod manifest, then failing to recover. Back up the manifest first, every time.
4. **Underestimating Falco and Cilium.** Falco is the most reported task family in the whole exam.
5. **Skipping a topic in preparation.** Every skipped domain showed up on someone's exam.

## The files here

- [`00-calendar.md`](00-calendar.md) — the twelve weekends, with checkboxes. Open it each Saturday.
- [`01-domain-checklists.md`](01-domain-checklists.md) — every curriculum bullet as a mastery line. Re-score on 8 Nov, 29 Nov and 5 Dec.
- [`02-resources.md`](02-resources.md) — KodeKloud mapping, the Killercoda scenario list, allowed documentation and the page titles to search for.
- [`03-exam-day-playbook.md`](03-exam-day-playbook.md) — read this the morning of the exam.

## Related

- [`../study-notes/`](../study-notes/) — the recipes each weekend works through
- [`../practice-cli/`](../practice-cli/) — the timed, verified questions
- [`../mock-exams/`](../mock-exams/) — the three scored mocks
- [`../lab-setup/README.md`](../lab-setup/README.md) — build both lab tiers before day one
- [`../../roadmap.md`](../../roadmap.md) — CKS and LFCS on one page
