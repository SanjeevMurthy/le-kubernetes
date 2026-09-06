# CKS — Certified Kubernetes Security Specialist

Everything needed to pass CKS on **Saturday 12 December 2026**: dated study plan, exam-task recipes, a practice CLI with automated verification, three scored mocks, and a lab you can build in an afternoon.

<!-- toc -->
## Table of Contents

- [What the exam is](#what-the-exam-is)
  - [Domains and weights](#domains-and-weights)
- [Start here](#start-here)
- [What is here](#what-is-here)
- [Practice CLI](#practice-cli)
- [Where the content comes from](#where-the-content-comes-from)
- [Safety](#safety)

<!-- toc stop -->

## What the exam is

Verified against Linux Foundation pages on 6 September 2026. Full detail in [`study-notes/00-exam-environment.md`](study-notes/00-exam-environment.md).

| | |
|---|---|
| Environment | Kubernetes **v1.35** (the published curriculum document is v1.34) |
| Format | 15 to 20 performance-based tasks, candidates consistently report 16. Two hours. |
| Pass mark | **67 percent**, so about 11 of 16 tasks solved cleanly. Partial credit counts. |
| Prerequisite | A passed CKA, which need not still be active |
| Hosts | One designated host per task via `ssh <nodename>` from `base`. No nested SSH. `sudo -i` for root. |
| Tools present | `kubectl` with a `k` alias, `yq`, `curl`, `wget`, `man`. **No `jq`.** |
| Docs allowed | kubernetes.io docs and blog, falco.org, the bom CLI reference, etcd.io, the ingress-nginx user guide, docs.cilium.io, istio.io. **Nothing else**, so Trivy, kube-bench, AppArmor and kubesec flags must be memorised. |
| Retake | One free retake within 12 months of purchase. Certification valid 2 years. |
| Bonus | Passing CKS on or after 18 June 2026 also extends the CKA under the CARE policy |

### Domains and weights

| Domain | Weight | Note |
|---|---|---|
| Cluster Setup | 15% | [`study-notes/01-cluster-setup.md`](study-notes/01-cluster-setup.md) |
| Cluster Hardening | 15% | [`study-notes/02-cluster-hardening.md`](study-notes/02-cluster-hardening.md) |
| System Hardening | 10% | [`study-notes/03-system-hardening.md`](study-notes/03-system-hardening.md) |
| Minimize Microservice Vulnerabilities | 20% | [`study-notes/04-microservice-vulnerabilities.md`](study-notes/04-microservice-vulnerabilities.md) |
| Supply Chain Security | 20% | [`study-notes/05-supply-chain-security.md`](study-notes/05-supply-chain-security.md) |
| Monitoring, Logging and Runtime Security | 20% | [`study-notes/06-monitoring-logging-runtime.md`](study-notes/06-monitoring-logging-runtime.md) |

## Start here

1. **Book the exam.** It releases the two killer.sh sessions and makes the calendar real.
2. **Build the lab**: [`lab-setup/README.md`](lab-setup/README.md). Two tiers, minikube with Calico plus the Killercoda playground.
3. **Read** [`study-notes/00-exam-environment.md`](study-notes/00-exam-environment.md) end to end.
4. **Open the calendar** every Saturday: [`study-plan/00-calendar.md`](study-plan/00-calendar.md).

## What is here

| Folder | What it is |
|---|---|
| [`study-plan/`](study-plan/) | The dated calendar from 26 Sep to 12 Dec, mastery checklists, resources, and the exam-day playbook |
| [`study-notes/`](study-notes/) | Seven notes as exam-task recipes, in curriculum order, plus the environment facts |
| [`practice-cli/`](practice-cli/) | Interactive questions with automated setup, verification and cleanup, a timer, and progress tracking |
| [`mock-exams/`](mock-exams/) | Three 16-task, 120-minute papers, scored by domain |
| [`cheatsheets/`](cheatsheets/) | The one-page reference and the Anki deck |
| [`lab-setup/`](lab-setup/) | How to build both lab tiers on this machine |
| [`practice-tests/`](practice-tests/) | Real exam task types compiled from candidate reports |

The four are cross-linked: read the **note** for a domain, drill the matching **practice-CLI** questions, sit a **mock**, and track it all in the **plan**.

## Practice CLI

```bash
cd cks/practice-cli
./cks --env      # what this host can run
./cks            # interactive
./cks --mock 1   # a scored 120-minute paper
```

The CLI refuses to run against a context whose name contains `aks`, `eks`, `gke` or `prod`, and against anything not on its allow-list. The active context on this machine is a work cluster, so that guard is not theoretical.

## Where the content comes from

Every frequency number in the notes ("12 sources") is a count of independent candidate reports from the research behind this kit: [`../docs/research/2026-09-06-cks-exam-research.md`](../docs/research/2026-09-06-cks-exam-research.md). It compiles 28 first-hand write-ups from 2021 to 2026, the official curriculum diffs, and the simulator and scenario catalogues. Nothing in the notes is invented, and where a claim is a synthesis rather than a report, the research file says so.

## Safety

These scenarios edit API server manifests, kubelet configuration, audit policy, encryption keys, AppArmor profiles and node services. Run them only on a disposable practice cluster. Always run cleanup when a question is done.
