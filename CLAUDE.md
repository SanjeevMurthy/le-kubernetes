# le-kubernetes

Kubestronaut certification preparation repository covering all 5 CNCF Kubernetes certifications.

## Repository Structure

```
le-kubernetes/
├── cka/              # CKA - Certified Kubernetes Administrator
├── ckad/             # CKAD - Certified Kubernetes Application Developer
├── cks/              # CKS - Certified Kubernetes Security Specialist
├── kcna/             # KCNA - Kubernetes and Cloud Native Associate
├── kcsa/             # KCSA - Kubernetes and Cloud Native Security Associate
└── shared/           # Common manifests and cluster setup scripts
```

## Conventions

- Each certification has its own top-level directory (lowercase)
- Directory names use lowercase with hyphens (no spaces)
- YAML manifests use descriptive filenames matching the K8s resource they define
- Practice CLI tools live under `cka/practice-cli/` with versioned subdirectories (v1, v2)
- Practice CLI scripts require Bash 4+ and a running Kubernetes cluster

## Key Paths

- **CKA cheatsheets**: `cka/cheatsheets/`
- **CKA practice CLI (latest)**: `cka/practice-cli/v2/cka`
- **CKA study guide (by domain)**: `cka/study-guide/{1-core-concepts,2-workloads-scheduling,3-services-and-networking,4-storage}/`
- **Shared K8s manifests**: `shared/manifests/`
- **Cluster setup**: `shared/cluster-setup/`

## Practice CLI Tool

The CKA practice CLI (`cka/practice-cli/v2/cka`) is a bash script that:
- Presents exam-style questions with automated lab setup
- Verifies solutions via kubectl checks
- Each question has `setup.sh`, `verify.sh`, and `cleanup.sh` in its directory
- Questions are defined in `lib/questions.sh` as a pipe-delimited array

## Working with this repo

- Do not commit secrets, keys, or credentials (enforced via `.gitignore`)
- PDFs and binary resources go under `<cert>/resources/`
- When adding new certification content, follow the existing directory pattern
