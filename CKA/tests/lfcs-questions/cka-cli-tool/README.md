# 🎯 CKA Exam Practice CLI

Interactive CLI tool for practicing CKA exam questions on any Kubernetes playground (Killercoda, minikube, kind, etc.)

## Quick Start

```bash
# On your K8s playground, clone the repo then:
cd CKA/tests/lfcs-questions/cka-cli-tool
chmod +x cka
./cka
```

## Features

- **📋 17 real CKA exam questions** — sourced from `cka-retake-questions-final.md`
- **⚙️ Automated lab setup** — creates K8s resources for each scenario
- **✅ Solution verification** — automated `kubectl` checks with pass/fail
- **⏱️ Built-in timer** — starts on setup, stops on verify, shows time spent
- **🏅 Performance feedback** — `<5 min` excellent, `5-10 min` good, `>10 min` needs practice
- **🧹 Cleanup** — removes all resources when done
- **💡 Solutions on demand** — view step-by-step answers from the retake guide

## Workflow

```
1. Select a question
2. [S] Setup → creates the scenario (timer starts ⏱️)
3. [Q] Read the question
4. Solve it yourself using kubectl!
5. [V] Verify → checks your solution (timer stops, shows time)
6. [H] Show solution if you're stuck
7. [C] Cleanup → removes all resources
```

## Directory Structure

```
cka-cli-tool/
├── cka                     # Main CLI (run this!)
├── lib/
│   ├── colors.sh           # Colors and print helpers
│   ├── menu.sh             # Interactive menus
│   └── questions.sh        # Question registry
├── questions/
│   ├── q01-cri-dockerd/    # Per-question folders
│   │   ├── setup.sh        # Lab setup script
│   │   ├── verify.sh       # Verification checks
│   │   └── cleanup.sh      # Resource teardown
│   ├── q02-cni-calico/
│   └── ... (q01–q17)
└── README.md
```

## Questions Covered

| Q#  | Topic                         | Domain          | Difficulty |
| --- | ----------------------------- | --------------- | ---------- |
| Q1  | Install cri-dockerd + Sysctl  | Cluster Setup   | Medium     |
| Q2  | Install CNI (Calico)          | Cluster Setup   | Medium     |
| Q3  | List cert-manager CRDs        | Cluster Setup   | Easy       |
| Q4  | Create PriorityClass          | Cluster Setup   | Easy       |
| Q5  | Helm Template ArgoCD          | Cluster Setup   | Medium     |
| Q6  | Create HPA with Stabilization | Workloads       | Medium     |
| Q7  | Fix Pending Pods — Resources  | Workloads       | Medium     |
| Q8  | Add Sidecar Container         | Workloads       | Easy       |
| Q9  | Taints and Tolerations        | Workloads       | Easy       |
| Q10 | Expose with NodePort          | Networking      | Easy       |
| Q11 | Create Ingress                | Networking      | Medium     |
| Q12 | Gateway API + TLS             | Networking      | Hard       |
| Q13 | NetworkPolicy                 | Networking      | Medium     |
| Q14 | ConfigMap TLS + Immutable     | Networking      | Medium     |
| Q15 | StorageClass Default          | Storage         | Medium     |
| Q16 | PVC + PV (MariaDB)            | Storage         | Medium     |
| Q17 | Fix kube-apiserver (etcd)     | Troubleshooting | Hard       |

## Requirements

- Bash 4+
- `kubectl` configured with cluster access
- A running Kubernetes cluster (Killercoda recommended)
