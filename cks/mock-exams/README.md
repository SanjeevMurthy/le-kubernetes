# CKS Mock Exams

Three full-length papers, 16 tasks each, 120 minutes, scored by weight with a per-domain breakdown. They exist to rehearse the two things that actually fail candidates: pace and verification under pressure.

<!-- toc -->
## Table of Contents

- [How to run one](#how-to-run-one)
- [Rules that make the practice worth anything](#rules-that-make-the-practice-worth-anything)
- [The three papers](#the-three-papers)
- [Score log](#score-log)
- [Related](#related)

<!-- toc stop -->

## How to run one

The mocks need a kubeadm cluster with root, because roughly half the tasks in each paper are node-level. Use the Killercoda Killer Shell CKS playground and install the tools first.

```bash
cd le-kubernetes/cks/practice-cli
sudo bash tools/install-tools.sh all
./cks --mock 1
```

The CLI runs every setup, starts one 120-minute timer, and shows the task list. Press `N` to read a task, `F` to finish and score, `C` to clean up. Questions whose `needs` tags the environment cannot satisfy are skipped and reported, and they score zero, so a mock run on minikube alone will under-report.

Each paper is also readable on its own as `mock-1.md`, `mock-2.md` and `mock-3.md` if you prefer to work from the text and verify by hand.

## Rules that make the practice worth anything

- No notes, no solutions, no documentation beyond what the exam allows: kubernetes.io, falco.org, the bom CLI reference, etcd.io, the ingress-nginx user guide, docs.cilium.io and istio.io.
- Work on the host each task names. Return to the base host between tasks.
- Flag anything that passes 10 minutes and move on. Come back at the end.
- Keep the last 15 minutes for verification, exactly as on exam day.
- Score before looking at any solution.

## The three papers

| Mock | Emphasis | Scheduled |
|---|---|---|
| 1 | Balanced across all six domains, the first honest measurement | Saturday 14 November 2026 |
| 2 | Control-plane heavy: API server, audit, encryption, ImagePolicyWebhook, CIS | Saturday 21 November 2026 |
| 3 | Everything not yet covered, plus a second pass at the five most-reported families | Saturday 5 December 2026 |

Pass mark is 67 percent, matching the real exam. Targets: 60 percent or better on mock 1, 75 on mock 2, 85 on mock 3. A score below target is information, not a verdict; the drill list it produces is the point.

## Score log

The CLI appends every run to `~/.cks-practice/mock-results.log`. Copy the results here so the trend is visible in one place.

| Date | Mock | Score | Time used | Weakest domain | Drill list |
|---|---|---|---|---|---|
| | | | | | |

## Related

- [`../study-plan/00-calendar.md`](../study-plan/00-calendar.md) — where the mocks sit in the schedule
- [`../study-plan/03-exam-day-playbook.md`](../study-plan/03-exam-day-playbook.md) — the ordering and verification habits to rehearse
- [`../practice-cli/README.md`](../practice-cli/README.md) — the CLI and its environment check
