# LFCS Resources

What to use, what each is uniquely good for, and where the gaps are. Ratings come from 21 candidate write-ups summarised in [`../../docs/research/2026-09-06-lfcs-exam-research.md`](../../docs/research/2026-09-06-lfcs-exam-research.md).

<!-- toc -->
## Table of Contents

- [Tier 1: the ones that decide the outcome](#tier-1-the-ones-that-decide-the-outcome)
- [KodeKloud section to note mapping](#kodekloud-section-to-note-mapping)
- [Free resources worth the time](#free-resources-worth-the-time)
- [Official](#official)
- [What to be careful with](#what-to-be-careful-with)
- [Documentation, and why practice must mirror it](#documentation-and-why-practice-must-mirror-it)
- [The lab](#the-lab)
- [Verify before you book](#verify-before-you-book)

<!-- toc stop -->

## Tier 1: the ones that decide the outcome

| Resource | Cost | What it uniquely gives you | Named by |
|---|---|---|---|
| **KodeKloud LFCS course and mocks** | Subscription you already hold | Guided coverage of all five domains with in-browser labs and four mock exams. Its community threads are also the best public record of what the mocks actually ask. | 10 of 21 write-ups |
| **killer.sh simulator** | Included with the voucher | 20 questions in an interface close to the real one. **Both sessions have the same questions**, unlike the Kubernetes simulators, so the second session is a re-test rather than new material. | 6 of 21 |
| **Your own lab** | Free | The only place you can break a boot, lock yourself out with a firewall rule, and recover. Seven of 21 write-ups built one and every one of them recommends it. | 7 of 21 |
| **This repo** | Free | Timed questions with automated setup and verification that check persistence separately from live effect, plus three scored mocks | — |

**How to sequence killer.sh.** Session 1 on 23 January as a diagnostic. Session 2 on 3 February as a re-test of the same questions, which is exactly what it is good for. The 36 hour clock starts on activation, so do not activate early.

## KodeKloud section to note mapping

One section per week, in the calendar's order rather than the course's.

| Week | KodeKloud section | Note |
|---|---|---|
| 14 to 20 Dec | Essential Commands, then Users and Groups | [`../study-notes/04-essential-commands.md`](../study-notes/04-essential-commands.md), [`../study-notes/05-users-and-groups.md`](../study-notes/05-users-and-groups.md) |
| 21 to 27 Dec | Operations and Deployment | [`../study-notes/01-operations-deployment.md`](../study-notes/01-operations-deployment.md) |
| 28 Dec to 3 Jan | Storage | [`../study-notes/03-storage.md`](../study-notes/03-storage.md) |
| 4 to 10 Jan | Networking | [`../study-notes/02-networking.md`](../study-notes/02-networking.md) |

**Known gaps in KodeKloud**, reported by a candidate who passed at 90 percent using it as the main source: no labs for LDAP, time synchronisation, reverse proxies or load balancers, and thin coverage of iptables and nftables. Those four are covered by this repo's notes and questions, and the firewall gap matters most because packet filtering with persistence is the single most reported task family on the exam.

## Free resources worth the time

- **Sander van Vugt's LFCS video course** (Pearson, O'Reilly, Coursera). Named by two write-ups. Strong on the RHEL-family side, which balances KodeKloud's Ubuntu focus.
- **Ghada Atef's LFCS-Lab-Scripts** on GitHub. Free, cross-distribution setup and verification scripts, and the closest public analogue to this repo's practice CLI. Her VM specification (five spare disks, four NICs) is more generous than ours and worth copying if disk allows.
- **giulianopz/lfcs** on GitHub. Notes organised by curriculum bullet with practice tasks; 275 stars.
- **willher/LFCS-Practice-Exam**. A 26-question, two-hour paper with answers.
- **Killercoda** has a free Ubuntu playground for quick command practice with no VM.
- **TecMint's LFCS series**, dated but broad.

## Official

- **LFS207 Linux System Administration Essentials**, 299 US dollars or bundled with the exam. 50 to 60 hours across 34 chapters, and the only official course aligned to the current curriculum. Candidate opinion is mixed: thorough, but thin on SSL, and older write-ups say the LF course alone is not enough.
- **The 2018 Certification Preparation Guide** is still online and describes the **pre-2023 six-domain curriculum**. Ignore it.

## What to be careful with

Several highly ranked "LFCS 2026" guides still print the old six-domain split (Essential Commands 25 percent, Operation of Running Systems 20 percent, Service Configuration 20 percent) and claim you choose between Ubuntu, openSUSE and CentOS Stream at scheduling. That was true before 11 May 2023 and is wrong now. If a guide lists six domains, close it.

Exam dump sites are worse than useless for a performance-based exam and using them breaches the certification agreement.

## Documentation, and why practice must mirror it

The exam allows **man pages, `/usr/share/doc` and installed packages only**. No browser, no internet.

The practical consequence is that studying with a browser open builds a habit you cannot use. From the first week, close it: when you would have searched, run `man -k` instead and time yourself. [`../cheatsheets/man-page-navigation.md`](../cheatsheets/man-page-navigation.md) is the technique, and the "command to page" table there is worth memorising.

## The lab

Build instructions: [`../lab-setup/README.md`](../lab-setup/README.md).

Two VirtualBox VMs on this Mac, Ubuntu 24.04 and Rocky 9, with spare disks for LVM, RAID, LUKS and quota work and a second NIC for addressing, bridging and routing. The Rocky VM is not optional: the curriculum names SELinux, and the exam may put you on a RHEL-family host.

Snapshot both as `clean` after provisioning and restore before every mock.

## Verify before you book

`https://docs.linuxfoundation.org/tc-docs/certification/instructions-lfcs-and-lfce` carries the task count, the allowed resources, the host rules and the port warning, and it changes without notice. Re-read it the week before booking and again the week before the exam.
