# LFCS Study Plan

A dated plan to pass LFCS on **Saturday 6 February 2027**, starting the day after the CKS exam.

<!-- toc -->
## Table of Contents

- [Your parameters](#your-parameters)
- [The three phases](#the-three-phases)
- [What makes this exam different](#what-makes-this-exam-different)
- [The principles the calendar is built on](#the-principles-the-calendar-is-built-on)
- [The files here](#the-files-here)
- [Related](#related)

<!-- toc stop -->

## Your parameters

| | |
|--|--|
| Prior certifications | CKA, CKAD, and CKS by December 2026 |
| Linux level | Comfortable on the command line; the gap is administration, not fluency |
| Study start | Sunday 13 December 2026, with the lab build |
| Time budget | 10 to 12 hours a week through January, easing in the final week. About 70 hours total. |
| Anchor course | KodeKloud LFCS, one section per week |
| Lab | One Ubuntu 24.04 VM and one Rocky 9 VM on this Mac |
| Final simulation | Two killer.sh sessions: 23 January and 3 February |
| Exam | Saturday 6 February 2027 |
| Voucher expiry | March 2027, which leaves roughly four weeks for the free retake |

## The three phases

| Phase | Dates | Goal |
|---|---|---|
| **1 Foundation** | 13 Dec to 10 Jan | Lab built, then one domain per week hands-on. Baseline mock on 10 Jan. |
| **2 Drills** | 11 to 31 Jan | Timed, interleaved repetition on both distributions. Two repo mocks, killer.sh session 1, reboot drills. |
| **3 Simulation** | 1 to 6 Feb | Close the gaps, killer.sh session 2, exam. |

Week by week: [`00-calendar.md`](00-calendar.md).

## What makes this exam different

You have passed three Kubernetes exams. Three things will feel wrong at first.

**No browser.** CKA, CKAD and CKS all allow kubernetes.io. LFCS allows man pages and nothing else. A competency you can only demonstrate with a search engine open is not yet a competency, which is why the checklist bar is "timed, from man pages alone".

**Persistence is graded.** In a Kubernetes exam, applying a manifest is the answer. Here the live command is only half of it, and the mark is in `/etc/fstab`, `/etc/sysctl.d`, a netplan file or an enabled unit. This is the most reported cause of failure.

**The blast radius is real.** A bad NetworkPolicy inconveniences a pod. A bad firewall rule or fstab line locks you out of the machine or stops it booting. Hence `sshd -t`, `visudo -c`, `findmnt --verify` and `netplan try` as reflexes, and hence VM snapshots before every session.

## The principles the calendar is built on

1. **Persistence first.** Every question's verifier checks the file, not just the running state. From week five the drill is to reboot the VM and re-run the verifier.
2. **Both distributions.** The curriculum names SELinux, so RHEL-family skills are not optional. Every networking, firewall and package recipe gives the Ubuntu and Rocky forms side by side, and the Rocky VM exists to practise them.
3. **Man pages from day one.** Close the browser during study. Reach for `man -k` and time yourself.
4. **Interleaving in the drill phase.** Never two consecutive questions from the same domain.
5. **Host discipline.** The lab uses `ssh node1` and `ssh node2` rather than a local shell, because the exam gives one host per task and candidates lose marks working on the wrong one.
6. **Timed practice.** Six minutes per task, measured. Anything slower joins the drill list.

## The files here

- [`00-calendar.md`](00-calendar.md) — eight weeks with checkboxes. Open it each weekend.
- [`01-domain-checklists.md`](01-domain-checklists.md) — every curriculum bullet as a mastery line. Re-score on 10 Jan, 24 Jan and 31 Jan.
- [`02-resources.md`](02-resources.md) — what to use, what each is uniquely good for, and where the gaps are.
- [`03-exam-day-playbook.md`](03-exam-day-playbook.md) — read this the evening before.

## Related

- [`../lab-setup/README.md`](../lab-setup/README.md) — build this first
- [`../study-notes/`](../study-notes/) — the recipes each week works through
- [`../practice-cli/`](../practice-cli/) — the timed, verified questions
- [`../mock-exams/`](../mock-exams/) — the three scored papers
- [`../../roadmap.md`](../../roadmap.md) — CKS and LFCS on one page
