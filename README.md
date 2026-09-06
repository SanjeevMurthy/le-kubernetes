# le-kubernetes

Kubernetes certification preparation repository for the **Kubestronaut** program — covering all 5 CNCF Kubernetes certifications with notes, manifests, cheatsheets, practice CLI tools, and hands-on exercises.

## Kubestronaut Certifications

| Certification | Type | Status | Directory |
|--------------|------|--------|-----------|
| **CKA** — Certified Kubernetes Administrator | Performance-based | Passed | [`cka/`](cka/) |
| **CKAD** — Certified Kubernetes Application Developer | Performance-based | Passed | [`ckad/`](ckad/) |
| **CKS** — Certified Kubernetes Security Specialist | Performance-based | In progress, exam 12 Dec 2026 | [`cks/`](cks/) |
| **LFCS** — Linux Foundation Certified System Administrator | Performance-based | Planned, exam 6 Feb 2027 | `lfcs/` (built Dec 2026) |
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

## CKA Practice CLI

An interactive CLI tool for practicing real CKA exam questions on any Kubernetes playground (Killercoda, minikube, kind, etc.).

### Quick Start

```bash
# On your K8s playground, clone the repo then:
cd cka/practice-cli/v2
chmod +x cka
./cka
```

### Features

- **22 exam-style questions** covering all CKA domains
- **Automated lab setup** — creates K8s resources for each scenario
- **Solution verification** — automated kubectl checks with pass/fail
- **Built-in timer** — tracks time per question with performance feedback
- **Solutions on demand** — view step-by-step answers when stuck
- **Cleanup** — removes all lab resources when done

### Questions Covered

| Domain | Topics |
|--------|--------|
| **Cluster Setup** | Helm, CNI (Calico), CRDs, container runtime, kubeadm init, Kustomize |
| **Workloads** | HPA, sidecar containers, PriorityClass, resource requests, run pod, pod security |
| **Networking** | ConfigMap TLS, Gateway API, Ingress, NodePort, NetworkPolicy |
| **Storage** | StorageClass defaults, PVC + PV |
| **Troubleshooting** | Control plane fix, CNI troubleshoot, cluster repair |

## CKAD Practice CLI

An interactive CLI tool for practicing real CKAD exam questions, with progress tracking and random question mode.

### Quick Start

```bash
cd ckad/practice-cli
chmod +x ckad
./ckad
```

### Features

- **24 exam-style questions** across all 5 CKAD domains (sourced from 12+ candidate reports)
- **Automated lab setup/verify/cleanup** with expected vs actual output on failures
- **Progress tracking** — per-domain completion stats, checkmarks in question list
- **Random question mode** — picks an incomplete question for exam simulation
- **Built-in timer** with pace feedback

### Questions Covered

| Domain | Topics |
|--------|--------|
| **Design & Build** | Podman image build, CronJob, Job from CronJob, PVC mount |
| **Deployment** | Canary deployment, rolling update/rollback, fix deprecated API |
| **Config & Security** | Secrets, ConfigMap mount, RBAC, ServiceAccount, SecurityContext, ResourceQuota |
| **Networking** | NodePort, service selector fix, Ingress, NetworkPolicy (labels/pod-to-pod/CIDR) |
| **Observability** | Readiness probe, CrashLoopBackOff debug |

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
