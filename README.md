# le-kubernetes

Kubernetes certification preparation repository for the **Kubestronaut** program — covering all 5 CNCF Kubernetes certifications with notes, manifests, cheatsheets, practice CLI tools, and hands-on exercises.

## Kubestronaut Certifications

| Certification | Type | Status | Directory |
|--------------|------|--------|-----------|
| **CKA** — Certified Kubernetes Administrator | Performance-based | Active | [`cka/`](cka/) |
| **CKAD** — Certified Kubernetes Application Developer | Performance-based | In Progress | [`ckad/`](ckad/) |
| **CKS** — Certified Kubernetes Security Specialist | Performance-based | Planned | [`cks/`](cks/) |
| **KCNA** — Kubernetes and Cloud Native Associate | Multiple choice | Planned | [`kcna/`](kcna/) |
| **KCSA** — Kubernetes and Cloud Native Security Associate | Multiple choice | Planned | [`kcsa/`](kcsa/) |

## Repository Structure

```
le-kubernetes/
├── cka/                    # CKA certification prep
│   ├── cheatsheets/        # Quick-reference guides for exam day
│   ├── study-guide/        # Exercises organized by exam domain (4 domains)
│   ├── course-notes/       # Udemy course notes (scheduling, networking, security, helm)
│   ├── practice-cli/       # Interactive CLI exam simulators (v1: 17q, v2: 22q)
│   ├── practice-tests/     # Practice tests (udemy, killercoda, exam questions)
│   ├── troubleshooting/    # Troubleshooting scenarios & study companion
│   └── resources/          # PDFs and reference materials
├── ckad/                   # CKAD certification prep
│   └── course-notes/       # Udemy course notes
├── cks/                    # CKS certification prep (placeholder)
├── kcna/                   # KCNA certification prep (placeholder)
├── kcsa/                   # KCSA certification prep (placeholder)
└── shared/                 # Common resources across all certs
    ├── manifests/          # K8s manifest examples (pods, replicasets, services)
    └── cluster-setup/      # Minikube setup & common commands
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
