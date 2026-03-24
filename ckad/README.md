# CKAD - Certified Kubernetes Application Developer

## Exam Domains & Weights (2025)

| Domain | Weight |
|--------|--------|
| Application Design and Build | 20% |
| Application Deployment | 20% |
| Application Observability and Maintenance | 15% |
| Application Environment, Configuration and Security | 25% |
| Services & Networking | 20% |

## Directory Structure

```
ckad/
├── course-notes/         # Udemy course notes
└── practice-cli/         # Interactive CLI exam simulator
    ├── ckad              # Main executable (24 questions)
    ├── ckad-exam-qa-guide.md  # Real exam Q&A guide (12+ candidate reports)
    ├── lib/              # Shared libraries (colors, menus, progress, questions)
    └── questions/        # 24 question directories (setup/verify/cleanup each)
```

## Practice CLI

An interactive CLI tool for practicing real CKAD exam questions on any Kubernetes playground.

### Quick Start

```bash
cd ckad/practice-cli
chmod +x ckad
./ckad
```

### Features

- **24 exam-style questions** across all 5 CKAD domains
- **Automated lab setup** — creates K8s resources for each scenario
- **Solution verification** — automated kubectl checks with expected vs actual output
- **Progress tracking** — per-domain completion stats with checkmarks
- **Random question mode** — picks a random incomplete question for exam simulation
- **Built-in timer** — tracks time per question with pace feedback
- **Solutions on demand** — extracted from the real exam Q&A guide

### Questions by Domain

| Domain | # | Topics |
|--------|---|--------|
| **D1: Application Design and Build** | 4 | Podman image build, CronJob, Job from CronJob, PVC mount |
| **D2: Application Deployment** | 3 | Canary deployment, rolling update/rollback, fix deprecated API |
| **D3: Application Environment, Configuration and Security** | 8 | Secrets (keyRef, env, volume), ConfigMap mount, RBAC, ServiceAccount, SecurityContext, ResourceQuota |
| **D4: Services and Networking** | 7 | NodePort, fix service selector, Ingress (create/fix), NetworkPolicy (labels/pod-to-pod/CIDR) |
| **D5: Application Observability and Maintenance** | 2 | Readiness probe, CrashLoopBackOff debug |

## Key Topics

- **Design & Build**: Multi-container pods, init containers, volumes, CronJobs, Jobs
- **Deployment**: Deployments, rolling updates, rollbacks, Helm, Kustomize
- **Observability**: Probes (liveness, readiness, startup), logging, debugging
- **Configuration & Security**: ConfigMaps, Secrets, ServiceAccounts, SecurityContext, ResourceQuotas
- **Networking**: Services, Ingress, NetworkPolicies
