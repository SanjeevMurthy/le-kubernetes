# CKS Practice CLI

Exam-style CKS questions with automated lab setup, effect-based verification, a per-question timer, progress tracking, and a scored 120-minute mock mode.

## Requirements

- **Bash**. The menus run on bash 3.2, so `--list` and `--env` work on macOS. Question scripts run on Linux and assume bash 4.
- **A disposable Kubernetes cluster.** Roughly half the questions only need `kubectl`; the rest need a root shell on a kubeadm node. See [`../lab-setup/README.md`](../lab-setup/README.md) for both tiers.
- `kubectl` on PATH with a working context.
- Per-question tools (Falco, Trivy, kube-bench, `runsc`, kubesec, bom, AppArmor utilities). Install them with `sudo bash tools/install-tools.sh all`.

## Quick start

On minikube with Calico, for the `kubectl`-level questions:

```bash
cd cks/practice-cli
./cks --env        # what this host can run
./cks              # interactive
```

On the Killercoda Killer Shell CKS playground, for everything else:

```bash
git clone -b cks https://github.com/SanjeevMurthy/le-kubernetes
cd le-kubernetes/cks/practice-cli
sudo bash tools/install-tools.sh all
./cks
```

## The safety guard

The CLI refuses to run against a context whose name contains `aks`, `eks`, `gke` or `prod`, and against any context not on its allow-list (`minikube`, `cks*`, `kubernetes-admin@kubernetes`, `kind-*`, `default`, `killercoda*`). Override with `CKS_ALLOW_CONTEXT=1` only when you are certain the cluster is disposable.

This is not theoretical. These questions edit RBAC, admission control, API server manifests, kubelet configuration and node files.

## Menu

| Key | Action |
|---|---|
| `1` | List every question with its domain, difficulty, needs tags and completion mark |
| `2` | Select a question |
| `3` | Random incomplete question |
| `4` | Progress, overall and per domain |
| `5` | Mock exam: one 120-minute timer, scored by weight and domain |
| `E` | Environment check: what this host can and cannot run |
| `Q` | Quit |

Inside a question: `S` setup, `Q` show the question, `H` show the solution, `V` verify, `C` cleanup, `B` back.

Non-interactive: `./cks --list`, `./cks --env`, `./cks --mock N`.

## How a question is built

```
questions/qNN-<slug>/
├── meta          # id, title, domain, domain_short, difficulty, needs,
│                 # weight, minutes, sources, host
├── question.md   # shown by [Q]: exam wording, exact names and paths
├── solution.md   # shown by [H]: steps, why, verification, allowed docs
├── setup.sh      # creates the real starting state and prints the scenario facts
├── verify.sh     # PASS/FAIL checks that test effect; non-zero exit on failure
└── cleanup.sh    # removes what setup created and restores every backup
```

`sources` records how many independent candidate reports mention that task type, taken from [`../practice-tests/exam-questions/cks-real-exam-questions.md`](../practice-tests/exam-questions/cks-real-exam-questions.md). It is why the question bank is weighted the way it is.

### Needs tags

`./cks --env` matches these against the current host and lists what is runnable.

| Tag | Means |
|---|---|
| `kubectl` | any cluster with a usable context |
| `cni-netpol` | a NetworkPolicy-enforcing CNI (Calico or Cilium) |
| `cni-cilium` | Cilium specifically |
| `ingress` | an ingress-nginx controller |
| `admission:kyverno`, `admission:gatekeeper` | that policy engine is installed |
| `istio` | Istio CRDs present |
| `node-root` | a root shell on a kubeadm node |
| `tool:<name>` | that binary is on PATH |

### Verification philosophy

Verifiers prove the mechanism works, not that a file contains the right words. A NetworkPolicy question runs a DNS lookup, an AppArmor question tries a write that must be denied, an encryption question reads the raw value out of etcd, an audit question checks the log actually grows.

Two rules follow from the exam environment and are enforced throughout:

- **Never grep compact JSON.** `kubectl -o json` is pretty-printed, so a pattern like `'"app":"backend"'` never matches. Use `-o jsonpath`.
- **Never use `jq`.** It does not exist on exam hosts. Use `-o jsonpath`, `-o go-template` or `yq`.

## Generated files

Never edit these by hand; regenerate them.

```bash
bash tools/build-registry.sh   # questions/*/meta -> lib/questions.sh
bash tools/build-guide.sh      # questions/*/     -> cks-exam-qa-guide.md
bash tools/build-mock.sh 1     # ../mock-exams/mock-1.set -> mock-1.md
```

Each generator refuses to overwrite its output when the inputs look wrong, so a half-finished edit cannot silently destroy the registry or the guide.

## State

Runtime state lives outside the repo in `~/.cks-practice`: the timer, completed question ids, mock results and file backups taken by setup scripts. Override with `CKS_STATE_DIR`. Deliverable files go to `/opt/course/<n>/` when writable, mirroring the exam, and to `~/cks-course/<n>/` otherwise.

## Safety

These scenarios edit API server manifests, kubelet configuration, audit policy, encryption keys, AppArmor profiles and node services. Run them only on a disposable practice cluster, and run `[C]` cleanup when a question is done. Cleanup restores every file a setup backed up.
