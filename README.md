# ☸️ le-kubernetes

Personal Kubernetes learning repository — notes, manifests, cheatsheets, and hands-on practice material for the **CKA** (Certified Kubernetes Administrator) and **CKAD** (Certified Kubernetes Application Developer) certifications.

---

## 📂 Repository Structure

```
le-kubernetes/
├── CKA/                          # CKA certification prep
│   ├── cheatsheet/               # Quick-reference cheatsheets
│   │   ├── cka-exam-cheatsheet.md
│   │   ├── exam-readiness.md
│   │   └── kubectl-imperative-commands.md
│   ├── cka-study-guide/          # Study guide exercises (4 domains)
│   │   ├── 1-core-concepts/
│   │   ├── 2-workloads-scheduling/
│   │   ├── 3-services-and-networking/
│   │   └── 4-storage/
│   ├── cka-v1/                   # CKA CLI practice tool v1 (17 questions)
│   ├── cka-v2/                   # CKA CLI practice tool v2 (updated)
│   ├── k8s-udemy-notes/          # Udemy course notes (helm, networking, scheduling, security)
│   ├── practice-tests/           # Practice tests from multiple sources
│   │   ├── k8s-udemy-tests/
│   │   ├── killrcoda-tests/
│   │   ├── lfcs-questions/
│   │   └── practice-tests/
│   └── troubleshooting/          # Troubleshooting scenarios & study companion
├── CKAD/                         # CKAD certification prep
│   └── k8s-udemy/                # Udemy course notes
├── pods/                         # Pod manifest examples & notes
├── replicasets/                  # ReplicaSet manifest examples
├── services/                     # Service manifest examples (NodePort)
├── namespace/                    # Namespace notes
├── minikube/                     # Minikube cluster setup scripts
├── utilities/                    # Utility scripts (bulk delete pods, etc.)
├── k8s-cluster-keys/             # SSH keys for K8s cluster access
├── pod-with-sidecar.yaml         # Sidecar container pattern example
├── minikube-commands.sh          # Common minikube & kubectl commands
├── dropbox.sh                    # Dropbox utility script
└── CKA Study Guide.pdf          # CKA study guide (PDF)
```

---

## 🎯 CKA Exam Practice CLI

An interactive CLI tool for practicing real CKA exam questions on any Kubernetes playground (Killercoda, minikube, kind, etc.). Available in two versions under `CKA/cka-v1/` and `CKA/cka-v2/`.

### Quick Start

```bash
# On your K8s playground, clone the repo then:
cd CKA/cka-v2
chmod +x cka
./cka
```

### Features

- 📋 **17 real CKA exam questions** covering all exam domains
- ⚙️ **Automated lab setup** — creates K8s resources for each scenario
- ✅ **Solution verification** — automated `kubectl` checks with pass/fail
- ⏱️ **Built-in timer** — tracks time per question with performance feedback
- 💡 **Solutions on demand** — view step-by-step answers when stuck
- 🧹 **Cleanup** — removes all lab resources when done

### Questions Covered

| Domain              | Topics                                                                   |
| ------------------- | ------------------------------------------------------------------------ |
| **Cluster Setup**   | cri-dockerd, CNI (Calico), cert-manager CRDs, PriorityClass, Helm/ArgoCD |
| **Workloads**       | HPA with stabilization, fix pending pods, sidecar containers, taints     |
| **Networking**      | NodePort, Ingress, Gateway API + TLS, NetworkPolicy, ConfigMap TLS       |
| **Storage**         | StorageClass defaults, PVC + PV (MariaDB)                                |
| **Troubleshooting** | Fix kube-apiserver (etcd)                                                |

---

## 📚 Cheatsheets

| File                                                                            | Description                                                                                                      |
| ------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------- |
| [kubectl-imperative-commands.md](CKA/cheatsheet/kubectl-imperative-commands.md) | Comprehensive imperative commands for all K8s resources (Pods, Deployments, Services, RBAC, Jobs, Ingress, etc.) |
| [cka-exam-cheatsheet.md](CKA/cheatsheet/cka-exam-cheatsheet.md)                 | Exam-focused quick reference                                                                                     |
| [exam-readiness.md](CKA/cheatsheet/exam-readiness.md)                           | Pre-exam readiness checklist and review                                                                          |

---

## 🖥️ Local Cluster Setup (Minikube)

A ready-made script to spin up a **CKA-ready multi-node minikube cluster**:

```bash
# Start a 3-node cluster with metrics-server, dashboard, and ingress
./minikube/setup-cka-minikube.sh
```

**Config:** 3 nodes · Kubernetes v1.34.0 · containerd runtime · 2 CPUs / 4 GB RAM per node

Common minikube commands (tunnel, port-forward, expose, dashboard) are documented in [`minikube-commands.sh`](minikube-commands.sh).

---

## 📝 Kubernetes Manifest Examples

Hands-on YAML examples organized by resource type:

| Directory               | Contents                             |
| ----------------------- | ------------------------------------ |
| `pods/`                 | Nginx pod, Nginx service, notes      |
| `replicasets/`          | BusyBox ReplicaSet, basic ReplicaSet |
| `services/`             | NodePort service example             |
| `namespace/`            | Namespace notes                      |
| `pod-with-sidecar.yaml` | Multi-container sidecar pattern      |

---

## 🛠️ Prerequisites

- **kubectl** — configured with cluster access
- **minikube** (optional) — for local cluster setup
- **Bash 4+** — required for the CKA CLI tool
- A running Kubernetes cluster (Killercoda, minikube, kind, etc.)

---

## 📖 Study Resources

- `CKA Study Guide.pdf` — comprehensive study guide
- `CKA/troubleshooting/` — troubleshooting scenarios + Certified Kubernetes Administrator Study Companion (PDF)
- `CKA/k8s-udemy-notes/` — structured Udemy course notes (helm, networking, scheduling, security)
- `CKA/cka-study-guide/` — domain-based exercises (core concepts, workloads, networking, storage)
