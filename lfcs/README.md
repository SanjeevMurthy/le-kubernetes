# LFCS — Linux Foundation Certified System Administrator

Everything needed to pass LFCS on **Saturday 6 February 2027**: a two-VM lab you can build in an afternoon, exam-task recipes for all five domains, a practice CLI that runs inside the lab, three scored mocks, and a dated study plan.

LFCS is not a CNCF exam. It is the extra requirement for **Golden Kubestronaut**, which is why it sits in this repository alongside the Kubernetes certifications.

<!-- toc -->
## Table of Contents

- [What the exam is](#what-the-exam-is)
  - [Domains](#domains)
- [The two things that decide the outcome](#the-two-things-that-decide-the-outcome)
- [Start here](#start-here)
- [What is here](#what-is-here)
- [Practice CLI](#practice-cli)
- [Where the content comes from](#where-the-content-comes-from)
- [Relationship to le-linux](#relationship-to-le-linux)

<!-- toc stop -->

## What the exam is

Verified against Linux Foundation pages on 6 September 2026. Full detail in [`study-notes/00-exam-environment.md`](study-notes/00-exam-environment.md).

| | |
|---|---|
| Format | **17 to 20 performance-based tasks**, 2 hours |
| Pass mark | **67 percent**, so about 12 of 18 solved cleanly |
| Prerequisites | None |
| Documentation | **Man pages, `/usr/share/doc` and installed packages only. No browser, no internet.** |
| Hosts | One designated host per task via `ssh <nodename>` from a `base` host that must never be rebooted. No nested SSH. `sudo -i` for root. |
| Never block | Ports **8080, 4505 and 4506**. Blocking any of them ends the session. |
| Distribution | Not stated officially. Ubuntu is most likely, RHEL-family nodes are possible, and SELinux is an explicit curriculum bullet. |
| Retake | One free retake within 12 months of purchase. Valid 2 years. |
| Simulator | Two killer.sh sessions, and unlike the Kubernetes exams **both have the same 20 questions**. |

### Domains

| Domain | Weight | Note |
|---|---|---|
| Operations Deployment | 25% | [`study-notes/01-operations-deployment.md`](study-notes/01-operations-deployment.md) |
| Networking | 25% | [`study-notes/02-networking.md`](study-notes/02-networking.md) |
| Storage | 20% | [`study-notes/03-storage.md`](study-notes/03-storage.md) |
| Essential Commands | 20% | [`study-notes/04-essential-commands.md`](study-notes/04-essential-commands.md) |
| Users and Groups | 10% | [`study-notes/05-users-and-groups.md`](study-notes/05-users-and-groups.md) |

## The two things that decide the outcome

Everything in this kit is shaped by the two failure modes candidates actually report.

**A change that does not survive a reboot scores zero.** `ip addr add` is not a network configuration, `mount` is not a mount, `systemctl start` is not an enabled service. Every recipe names the file that persists the change, and every practice verifier checks persistence separately from live effect.

**There is no browser.** Coming from CKA, CKAD or CKS this is the biggest adjustment. Finding the right man page in under thirty seconds is a skill, and [`cheatsheets/man-page-navigation.md`](cheatsheets/man-page-navigation.md) is how to build it. The mastery bar in the checklists is deliberately "timed, from man pages alone".

## Start here

1. **Book the exam** for Saturday 6 February 2027. It releases the two killer.sh sessions.
2. **Build the lab**: [`lab-setup/README.md`](lab-setup/README.md). One Ubuntu 24.04 VM and one Rocky 9 VM, with the spare disks and second NIC that make storage and networking practice possible.
3. **Read** [`study-notes/00-exam-environment.md`](study-notes/00-exam-environment.md) end to end.
4. **Follow the calendar**: [`study-plan/00-calendar.md`](study-plan/00-calendar.md), eight weeks from 13 December.

## What is here

| Folder | What it is |
|---|---|
| [`study-plan/`](study-plan/) | The dated calendar, mastery checklists, resources, and the exam-day playbook |
| [`study-notes/`](study-notes/) | Seven notes as exam-task recipes, plus the environment facts and a basics refresher |
| [`lab-setup/`](lab-setup/) | VM creation and provisioning scripts, and how to snapshot |
| [`practice-cli/`](practice-cli/) | Questions with automated setup, verification and cleanup, run as root inside the lab |
| [`mock-exams/`](mock-exams/) | Three 18-task, 120-minute papers, scored by domain |
| [`cheatsheets/`](cheatsheets/) | The one-page reference, man-page navigation, and the Anki deck |
| [`practice-tests/`](practice-tests/) | Real exam task types compiled from candidate reports |

## Practice CLI

```bash
cd ~/le-kubernetes/lfcs/practice-cli
sudo ./lfcs --env      # what this host can run
sudo ./lfcs
```

It runs as root and **refuses to start on any host without `/etc/lfcs-lab`**, the marker the provisioning scripts write. Its questions create users, repartition disks, rewrite firewall rules and restart services, so that guard is the difference between a practice lab and a bad afternoon.

## Where the content comes from

Every frequency number in the notes is a count of independent candidate reports, traceable to [`../docs/research/2026-09-06-lfcs-exam-research.md`](../docs/research/2026-09-06-lfcs-exam-research.md). That research also records what could not be verified: the Linux Foundation does not publish which distribution the exam uses and declined to answer when asked on its own forum, so this kit prepares for both families rather than guessing.

## Relationship to le-linux

The separate [le-linux](https://github.com/SanjeevMurthy/le-linux) repository holds deep Linux material written for senior SRE interviews: kernel internals, CPU scheduling, memory management, performance debugging. It is excellent background and mostly deeper than this exam needs. This kit is task-oriented instead, and the notes link to le-linux where the underlying mechanism is worth understanding rather than merely operating.
