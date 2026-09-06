# LFCS Mock Exams

Three full-length papers, 18 tasks each, 120 minutes, scored by weight with a per-domain breakdown. They rehearse the two things that actually decide this exam: pace, and whether your changes survive a reboot.

<!-- toc -->
## Table of Contents

- [Before you start: restore the snapshot](#before-you-start-restore-the-snapshot)
- [How to run one](#how-to-run-one)
- [Rules that make the practice worth anything](#rules-that-make-the-practice-worth-anything)
- [The reboot round](#the-reboot-round)
- [The three papers](#the-three-papers)
- [Score log](#score-log)
- [Related](#related)

<!-- toc stop -->

## Before you start: restore the snapshot

```bash
VBoxManage snapshot lfcs-ubuntu restore clean
VBoxManage startvm lfcs-ubuntu --type headless
```

A mock is only a measurement if every run starts from the same place. Practice leaves users, mounts, firewall rules and services behind, and any of them can make a later task pass or fail for the wrong reason.

## How to run one

```bash
ssh node1
cd ~/le-kubernetes/lfcs/practice-cli
sudo ./lfcs --mock 1
```

The CLI runs every setup, starts one 120-minute timer, and shows the task list. Press `N` to read a task, `F` to finish and score, `C` to clean up. Questions whose `needs` tags this host cannot satisfy are skipped, reported, and scored zero, so a mock run only on Ubuntu will under-report the SELinux and firewalld tasks. Mock 2 is the one that notices most.

Each paper is also readable as `mock-1.md`, `mock-2.md` and `mock-3.md` if you would rather work from text and verify by hand.

## Rules that make the practice worth anything

- **No browser.** Man pages, `/usr/share/doc` and installed packages only, exactly as in the exam.
- Work on the host each task names, and return to base between tasks.
- Flag anything past 8 minutes and move on.
- Keep the last 15 minutes for verification, and spend it asking the reboot question rather than starting new work.
- Score before looking at any solution.

## The reboot round

This is the part that generic mocks skip and this exam punishes. After scoring, before cleaning up:

```bash
sudo reboot
# wait, reconnect, then re-run the verifiers:
sudo ./lfcs --mock 1     # press F to score again without redoing setup
```

Anything that passed before the reboot and fails after was never really done. On the real exam that difference is the difference between passing and not.

## The three papers

| Mock | Emphasis | Scheduled |
|---|---|---|
| 1 | Broad coverage across all five domains, as a baseline | Sunday 10 January 2027 |
| 2 | The RHEL-family half and the harder services work. Run this one on `lfcs-rocky`. | Saturday 16 January 2027 |
| 3 | Everything not yet covered, plus a second pass at firewalls, LVM, OpenSSL, containers and NFS | Sunday 31 January 2027 |

Pass mark is 67 percent, matching the real exam. Targets: 55 percent or better on mock 1, 70 on mock 2, 85 on mock 3. A low first score is information, not a verdict; the drill list it produces is the point.

## Score log

The CLI appends every run to `/var/lib/lfcs/mock-results.log`. Copy the results here so the trend is visible in one place.

| Date | Mock | Host | Score | Time used | Survived reboot? | Weakest domain |
|---|---|---|---|---|---|---|
| | | | | | | |

## Related

- [`../study-plan/00-calendar.md`](../study-plan/00-calendar.md) — where the mocks sit in the schedule
- [`../study-plan/03-exam-day-playbook.md`](../study-plan/03-exam-day-playbook.md) — the habits to rehearse
- [`../lab-setup/README.md`](../lab-setup/README.md) — snapshots, and how to restore them
