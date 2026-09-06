# le-kubernetes

Kubernetes certification preparation repository for the **Kubestronaut** program — covering all 5 CNCF Kubernetes certifications with notes, manifests, cheatsheets, practice CLI tools, and hands-on exercises.

## Kubestronaut Certifications

| Certification | Type | Status | Directory |
|--------------|------|--------|-----------|
| **CKA** — Certified Kubernetes Administrator | Performance-based | Passed | [`cka/`](cka/) |
| **CKAD** — Certified Kubernetes Application Developer | Performance-based | Passed | [`ckad/`](ckad/) |
| **CKS** — Certified Kubernetes Security Specialist | Performance-based | In progress, exam 12 Dec 2026 | [`cks/`](cks/) |
| **LFCS** — Linux Foundation Certified System Administrator | Performance-based | In progress, exam 6 Feb 2027 | [`lfcs/`](lfcs/) |
| **KCNA** — Kubernetes and Cloud Native Associate | Multiple choice | Planned | [`kcna/`](kcna/) |
| **KCSA** — Kubernetes and Cloud Native Security Associate | Multiple choice | Planned | [`kcsa/`](kcsa/) |

LFCS is not a CNCF exam; it is the extra requirement for **Golden Kubestronaut**. The combined schedule for both live exams is in [`roadmap.md`](roadmap.md).

## Repository Structure

```
le-kubernetes/
├── cka/                    # CKA prep (cheatsheets, study guide, course notes, 2 practice CLIs)
├── ckad/                   # CKAD prep (course notes, 24-question practice CLI)
├── cks/                    # CKS prep
│   ├── study-plan/         # dated calendar, domain checklists, resources, exam-day playbook
│   ├── study-notes/        # seven exam-task-recipe notes, in curriculum order
│   ├── practice-cli/       # per-question labs with setup, verify, cleanup and mock mode
│   ├── mock-exams/         # scored 120-minute papers
│   ├── cheatsheets/        # one-page reference and Anki deck
│   ├── lab-setup/          # how to build both lab tiers
│   └── practice-tests/     # real exam task types compiled from candidate reports
├── lfcs/                   # LFCS prep (same shape as cks/)
├── kcna/  kcsa/            # placeholders
├── shared/                 # manifests and cluster setup shared across certs
├── scripts/                # check-docs.sh and friends: links, TOCs, mermaid, shell syntax
├── docs/research/          # the evidence the study material is built on
├── docs/superpowers/       # design spec and implementation plans
└── roadmap.md              # CKS and LFCS on one page
```

## Practice CLIs

Four interactive harnesses. CKA and CKAD are the originals, which got their exams passed. CKS is the current design and LFCS follows it.

| Cert | Entry point | Questions | Runs on |
|---|---|---|---|
| CKA | `cka/practice-cli/v2/cka` | 22 | any cluster |
| CKAD | `ckad/practice-cli/ckad` | 24 | any cluster |
| CKS | `cks/practice-cli/cks` | see `--list` | minikube with Calico, plus Killercoda for node-level work |
| LFCS | `lfcs/practice-cli/lfcs` | see `--list` | as root inside the lab VMs |

```bash
cd cks/practice-cli && ./cks --env      # what this host can run
cd cks/practice-cli && ./cks            # interactive
cd cks/practice-cli && ./cks --mock 1   # a scored 120-minute paper
```

The CKS and LFCS harnesses build every question from a self-contained folder holding a `meta` file, the question, the solution, and setup, verify and cleanup scripts. Verifiers test effect rather than file text: a NetworkPolicy question runs a DNS lookup, an encryption question reads the raw value out of etcd, and every LFCS question checks that the change survives a reboot.

Both refuse to run where they could do damage. CKS rejects any kubectl context matching `aks`, `eks`, `gke` or `prod`; LFCS requires root and a lab marker file.

## Verification

```bash
bash scripts/check-docs.sh          # must print: check-docs: ALL OK
```

It runs `bash -n` and shellcheck over every script, resolves every relative link and heading anchor, verifies every table of contents is current, and lints and renders every mermaid diagram. Run it before each commit.

## Cheatsheets

| File | Description |
|------|-------------|
| [kubectl-imperative-commands.md](cka/cheatsheets/kubectl-imperative-commands.md) | Comprehensive imperative commands for all K8s resources |
| [cka-exam-cheatsheet.md](cka/cheatsheets/cka-exam-cheatsheet.md) | Exam-focused quick reference |
| [exam-readiness.md](cka/cheatsheets/exam-readiness.md) | Pre-exam readiness checklist |

## Local Cluster Setup

```bash
# Minikube setup script (if available locally)
# Common minikube & kubectl commands:
cat shared/cluster-setup/minikube-commands.sh
```

## Prerequisites

- **kubectl** — configured with cluster access
- **minikube** (optional) — for local cluster setup
- **Bash 4+** — required for the CKA CLI tool
- A running Kubernetes cluster (Killercoda, minikube, kind, etc.)
