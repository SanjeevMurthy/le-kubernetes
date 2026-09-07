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
├── scripts/                # check-docs.sh and friends: the whole verification gate
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
| CKS | `cks/practice-cli/cks` | 44 | minikube with Calico, plus Killercoda for node-level work |
| LFCS | `lfcs/practice-cli/lfcs` | 45 | as root inside the lab VMs |

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

Run it before each commit. It is offline and fast, and it checks:

| Step | What it refuses to let through |
|---|---|
| `bash -n`, shellcheck | a script that does not parse, or a shellcheck warning |
| `test-libs.sh` | a regression in the helpers every question shares |
| `check-question-refs.py` | a note or mock set naming a question that does not exist |
| `check-persistence.py` | an LFCS verifier that never checks a change survives a reboot |
| `check-cleanup-safety.py` | a cleanup that deletes an account it did not create, flushes the host firewall, or restores a whole-file `/etc/fstab` |
| `build-lab-table.py --check` | a "which questions run where" table that has drifted from the question metas |
| `check-links.py` | a broken relative link or heading anchor |
| `generate_toc.py --check` | a stale table of contents |
| `check-mermaid.sh` | a diagram that does not render |

Two more tools sit outside the gate:

```bash
bash scripts/regenerate.sh                  # rebuild every generated file
python3 scripts/check-external-links.py     # fetch every cited URL
```

Run `regenerate.sh` after adding or retagging a question; it rebuilds the registries, guides, mock papers, lab tables and tables of contents. The link checker is separate because it needs the network.

## Cheatsheets

| File | Description |
|------|-------------|
| [kubectl-imperative-commands.md](cka/cheatsheets/kubectl-imperative-commands.md) | Comprehensive imperative commands for all K8s resources |
| [cka-exam-cheatsheet.md](cka/cheatsheets/cka-exam-cheatsheet.md) | Exam-focused quick reference |
| [exam-readiness.md](cka/cheatsheets/exam-readiness.md) | Pre-exam readiness checklist |
| [cks-exam-cheatsheet.md](cks/cheatsheets/cks-exam-cheatsheet.md) | One page for the CKS, with the eight allowed documentation domains |
| [lfcs-exam-cheatsheet.md](lfcs/cheatsheets/lfcs-exam-cheatsheet.md) | One page for the LFCS, Ubuntu and Rocky commands side by side |
| [man-page-navigation.md](lfcs/cheatsheets/man-page-navigation.md) | Finding an answer in `man` under time pressure, since the LFCS allows no browser |

Anki decks for both new exams are in the same directories, as `cks-anki-deck.txt` and `lfcs-anki-deck.txt`.

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
