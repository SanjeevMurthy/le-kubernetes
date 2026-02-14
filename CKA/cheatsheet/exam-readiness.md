# 🎯 CKA Exam Readiness Guide

> Your complete guide to understanding the CKA exam format, scoring, strategy, and tips to pass on the first attempt.

---

## Table of Contents

1. [Exam Overview](#exam-overview)
2. [Exam Format & Structure](#exam-format--structure)
3. [Domain Weights & Curriculum](#domain-weights--curriculum)
4. [Scoring & Passing Criteria](#scoring--passing-criteria)
5. [What's New in 2025](#whats-new-in-2025)
6. [Exam Environment Setup](#exam-environment-setup)
7. [Time Management Strategy](#time-management-strategy)
8. [Before the Exam — Setup Checklist](#before-the-exam--setup-checklist)
9. [During the Exam — Tips & Tricks](#during-the-exam--tips--tricks)
10. [Terminal & kubectl Speed Hacks](#terminal--kubectl-speed-hacks)
11. [Vim Survival Guide for Exam](#vim-survival-guide-for-exam)
12. [Documentation Navigation](#documentation-navigation)
13. [Common Mistakes to Avoid](#common-mistakes-to-avoid)
14. [Study Plan & Resources](#study-plan--resources)
15. [Readiness Self-Assessment](#readiness-self-assessment)

---

## Exam Overview

| Detail                     | Value                                                         |
| -------------------------- | ------------------------------------------------------------- |
| **Full Name**              | Certified Kubernetes Administrator                            |
| **Offered by**             | CNCF (Cloud Native Computing Foundation) via Linux Foundation |
| **Exam Type**              | 100% Performance-based (hands-on, no MCQ)                     |
| **Proctoring**             | Remote, online-proctored via PSI                              |
| **Duration**               | **2 hours** (120 minutes)                                     |
| **Number of Questions**    | **15–20 tasks** (typically ~17)                               |
| **Passing Score**          | **66%**                                                       |
| **Open Book?**             | ✅ Yes — access to official Kubernetes docs allowed           |
| **Retakes Included**       | 1 free retake (if you fail)                                   |
| **Certification Validity** | 2 years (renewable with re-exam)                              |
| **Kubernetes Version**     | Aligned with latest minor version (~v1.32+)                   |
| **Cost**                   | $395 USD (includes 1 free retake + 2 Killer.sh sessions)      |
| **Language**               | English, Japanese, Chinese, Spanish                           |

---

## Exam Format & Structure

### What to Expect

- You work in a **browser-based Linux terminal** connected to pre-configured Kubernetes clusters
- Each question provides a **context** (which cluster to use) — you must switch to it
- Tasks require you to **create, modify, debug, or troubleshoot** Kubernetes resources
- You type real commands — no GUI, no drag-and-drop, no multiple choice
- You can open **one additional browser tab** for Kubernetes documentation

### Question Characteristics

| Aspect                   | Details                                                 |
| ------------------------ | ------------------------------------------------------- |
| **Format**               | Performance-based tasks solved via command line         |
| **Weightage**            | Each question has a specific percentage weight (4%–13%) |
| **Partial Credit**       | ✅ Yes — you get credit for partial completion          |
| **Multiple Clusters**    | Questions use different clusters — always check context |
| **Average per Question** | ~6-7 minutes per question                               |

---

## Domain Weights & Curriculum

The CKA exam covers **5 domains** with specific weight percentages:

```
┌──────────────────────────────────────────────────────────┐
│                   CKA Exam Domains                       │
├──────────────────────────────────────────────┬───────────┤
│ Domain                                       │  Weight   │
├──────────────────────────────────────────────┼───────────┤
│ 🔴 Troubleshooting                           │   30%     │
│ 🟠 Cluster Architecture, Install & Config    │   25%     │
│ 🟡 Services & Networking                     │   20%     │
│ 🟢 Workloads & Scheduling                    │   15%     │
│ 🔵 Storage                                   │   10%     │
└──────────────────────────────────────────────┴───────────┘
```

### Domain Breakdown

#### 🔴 Troubleshooting (30%) — Highest Weight!

- Evaluate cluster and node logging
- Understand how to monitor applications
- Manage container stdout/stderr logs
- Troubleshoot application failures
- Troubleshoot cluster component failures
- Troubleshoot networking issues
- Fix broken kubelet, DNS, networking
- **Diagnose crashing Pods, CrashLoopBackOff, ImagePullBackOff**

#### 🟠 Cluster Architecture, Installation & Configuration (25%)

- Manage RBAC (Role, ClusterRole, Bindings)
- Use kubeadm to install a Kubernetes cluster
- Manage a highly-available Kubernetes cluster (etcd backup/restore)
- Provision underlying infrastructure for cluster deployment
- Perform version upgrades using kubeadm
- Implement etcd backup and restore
- Understand CRDs and Operators
- Use Helm and Kustomize to manage manifests

#### 🟡 Services & Networking (20%)

- Understand Host networking configuration on cluster nodes
- Understand connectivity between Pods
- Understand ClusterIP, NodePort, LoadBalancer service types
- Know how to use Ingress controllers and Ingress resources
- Know how to configure and use CoreDNS
- Understand and define Network Policies
- Understand the Gateway API (new in 2025)

#### 🟢 Workloads & Scheduling (15%)

- Understand deployments and how to perform rolling updates/rollbacks
- Use ConfigMaps and Secrets to configure applications
- Know how to scale applications (manual + HPA)
- Understand resource limits and Pod scheduling
- Understand the primitives used to create self-healing applications
- Awareness of manifest management tools (Helm/Kustomize)
- Pod admission and scheduling (taints, tolerations, affinity, nodeSelector)

#### 🔵 Storage (10%)

- Understand storage classes, persistent volumes
- Understand volume types and access modes
- Know how to configure applications with persistent storage
- Understand PV, PVC lifecycle and reclaim policies

---

## Scoring & Passing Criteria

### The Math

```
┌───────────────────────────────────────────────────────────┐
│                  Passing Calculation                       │
├───────────────────────────────────────────────────────────┤
│  Total Score:        100%                                 │
│  Passing Score:       66%                                 │
│  You can FAIL:       34% of the exam and still pass       │
│                                                           │
│  ~17 questions × varying weights = 100%                   │
│  You need ≥ 66 points out of 100                          │
│                                                           │
│  With partial credit, even partially solved questions     │
│  contribute to your score!                                │
└───────────────────────────────────────────────────────────┘
```

### What This Means Practically

- **You do NOT need to answer every question**
- If there are 17 questions, you can skip 2-3 low-weight ones and still pass
- **Partial credit matters** — always attempt something, even if incomplete
- Focus on accuracy over speed for high-weight questions

### Scoring Strategy

| Question Weight | Priority                           | Time Allocation |
| --------------- | ---------------------------------- | --------------- |
| 8–13%           | 🔴 HIGH — do these first           | 8–10 min        |
| 5–7%            | 🟡 MEDIUM — do after high priority | 5–7 min         |
| 2–4%            | 🟢 LOW — do last or skip if stuck  | 3–5 min         |

---

## What's New in 2025

> [!IMPORTANT]
> The CKA exam was updated on **February 18, 2025**. Key changes include:

### Topics Added ✅

- Custom Resource Definitions (CRDs) and Operators
- Helm chart management and usage
- Kustomize for manifest management
- Network Policies (define and enforce)
- Gateway API for ingress traffic management
- Priority Classes for Pod scheduling
- Extension interfaces (CNI, CSI, CRI) — conceptual understanding

### Topics Removed / De-emphasized ❌

- Manual etcd backup/restore (reduced emphasis, may still appear)
- Updating cluster components using `kubeadm` (reduced weight)

---

## Exam Environment Setup

### What You'll See

```
┌─────────────────────────────────────────────────────────┐
│  Browser Window                                          │
│  ┌──────────────────────┬──────────────────────────────┐ │
│  │   Question Panel     │    Terminal (Linux)           │ │
│  │                      │    $ kubectl get pods         │ │
│  │   Q1 (7%)            │                               │ │
│  │   Context: k8s-c1    │    NAME    READY  STATUS      │ │
│  │                      │    nginx   1/1    Running     │ │
│  │   Create a pod...    │                               │ │
│  │                      │    $                          │ │
│  │   [Flag] [Next]      │                               │ │
│  └──────────────────────┴──────────────────────────────┘ │
│  ┌──────────────────────────────────────────────────────┐ │
│  │  Additional Tab: kubernetes.io/docs (allowed)        │ │
│  └──────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

### Pre-configured in the Environment

- `kubectl` is already installed and configured
- `k` alias for `kubectl` is already set
- `bash` autocompletion is available
- Multiple clusters are pre-configured in kubeconfig
- `vim`/`vi`, `nano` text editors are available
- `jq`, `curl`, `wget` available
- `sudo` access on nodes when needed

### Allowed Resources During Exam

| ✅ Allowed                                              | ❌ Not Allowed                   |
| ------------------------------------------------------- | -------------------------------- |
| [kubernetes.io/docs](https://kubernetes.io/docs/)       | Personal notes or bookmarks      |
| [kubernetes.io/blog](https://kubernetes.io/blog/)       | ChatGPT, AI tools                |
| [github.com/kubernetes](https://github.com/kubernetes/) | External websites                |
| One additional browser tab                              | Copy-paste from external sources |

---

## Time Management Strategy

### The 3-Pass Approach

```
Pass 1 (0:00 – 1:00): Quick Wins
├── Read ALL questions first, note weights
├── Solve easy questions you're confident about
├── Flag anything that looks complex or unfamiliar
├── Target: Complete 10-12 questions
│
Pass 2 (1:00 – 1:40): Medium Difficulty
├── Tackle flagged medium-difficulty questions
├── Use documentation if needed
├── Don't spend >8 min on any single question
├── Target: Complete 3-5 more questions
│
Pass 3 (1:40 – 2:00): Review & Partial Credit
├── Attempt remaining flagged questions
├── Do as much as possible for partial credit
├── Double-check context switches on completed questions
├── Verify key answers (kubectl get, describe)
└── Target: Squeeze out remaining points
```

### Time Budget Per Question

| Questions                  | Avg Time      | Strategy      |
| -------------------------- | ------------- | ------------- |
| 6 quick ones (~3-4% each)  | 3-4 min each  | ~24 min total |
| 7 medium ones (~5-7% each) | 5-7 min each  | ~42 min total |
| 4 hard ones (~8-13% each)  | 8-10 min each | ~36 min total |
| **Review buffer**          |               | **~18 min**   |
| **Total**                  |               | **120 min**   |

> [!WARNING]
> **The #1 time killer:** Getting stuck on one hard question for 15+ minutes. Set a mental timer — if you're stuck after 7 minutes, FLAG IT and move on.

---

## Before the Exam — Setup Checklist

### Physical Setup

- [ ] **Quiet, private room** — no one else can be present
- [ ] **Clean desk** — remove all papers, books, second monitors
- [ ] **Webcam and microphone** — required and must stay on
- [ ] **Stable internet** — wired connection preferred
- [ ] **Government-issued photo ID** — passport or driver's license
- [ ] **Close all other applications** — only the exam browser should be open
- [ ] **Disable notifications** — phone on silent, computer notifications off

### System Requirements

- [ ] Latest Chrome or Chromium-based browser
- [ ] PSI Secure Browser installed and tested
- [ ] Run PSI system check at least **24 hours before** exam
- [ ] Minimum 4GB RAM, stable internet (5+ Mbps)

### Mental Preparation

- [ ] Get 7-8 hours of sleep the night before
- [ ] Eat a light meal before the exam
- [ ] Use the bathroom before starting (2 hours is long!)
- [ ] Have water nearby (clear, unlabeled bottle allowed)
- [ ] Take 2 Killer.sh practice exams within the week before

---

## During the Exam — Tips & Tricks

### 🏆 Top 10 Exam Tips

#### 1. Always Check the Context First

```bash
# EVERY question specifies a context — ALWAYS switch to it
kubectl config use-context <context-name>

# Verify you're on the right cluster
kubectl config current-context
```

> [!CAUTION]
> **This is the #1 cause of failed questions.** Working on the wrong cluster means zero points, even if your solution is technically correct.

#### 2. Use Imperative Commands — Don't Write YAML From Scratch

```bash
# FAST: imperative
kubectl run nginx --image=nginx --port=80

# SLOW: writing YAML from scratch — avoid unless necessary
```

#### 3. Generate YAML Templates with Dry-Run

```bash
# Generate, edit, apply — the golden workflow
kubectl run nginx --image=nginx --dry-run=client -o yaml > pod.yaml
vim pod.yaml  # add what you need
kubectl apply -f pod.yaml
```

#### 4. Use `kubectl explain` Instead of Searching Docs

```bash
# Faster than opening docs — shows field hierarchy
kubectl explain pod.spec.containers.livenessProbe
kubectl explain deploy.spec.strategy
kubectl explain pv.spec --recursive  # show all fields
```

#### 5. Copy-Paste from Questions — Never Type Resource Names

- Copy pod names, image names, namespace names directly from the question
- Typos cost time and points
- Use the browser copy: `Ctrl+C`, terminal paste: `Ctrl+Shift+V` (or right-click)

#### 6. Always Validate Your Work

```bash
# After creating anything, verify it's correct
kubectl get pod <name> -o wide
kubectl describe pod <name>
kubectl logs <name>

# For services
kubectl get svc <name>
kubectl get endpointslice -l kubernetes.io/service-name=<name>
```

#### 7. Delete Pods Fast

```bash
# Regular delete waits 30 seconds — too slow!
kubectl delete pod nginx --grace-period 0 --force

# Or export this function at the start
export do="--dry-run=client -o yaml"
export now="--grace-period 0 --force"
# Usage: k delete pod nginx $now
```

#### 8. Partial Credit — Always Attempt Something

- Even if you can't finish, create what you can
- Create the namespace, create the pod without all specs
- Add labels, create the service — each piece may earn partial credit

#### 9. Use `kubectl get -o yaml` to Copy From Existing Resources

```bash
# Need to create something similar to an existing resource?
kubectl get pod existing-pod -o yaml > new-pod.yaml
# Edit the name, remove system fields, apply
```

#### 10. Keep Track of Questions You've Flagged

- The exam interface lets you flag questions
- Flag anything you skip — come back in Pass 2 or 3
- Don't lose points by forgetting to return

---

## Terminal & kubectl Speed Hacks

### Essential Aliases (Pre-set in Exam)

```bash
# These are already configured in the exam environment:
alias k=kubectl
complete -o default -F __start_kubectl k  # autocompletion for 'k'
```

### Additional Time-Saving Exports

Set these at the start of your exam:

```bash
# Quick dry-run output
export do="--dry-run=client -o yaml"
# Usage: k run nginx --image=nginx $do > pod.yaml

# Quick force delete
export now="--grace-period 0 --force"
# Usage: k delete pod nginx $now
```

### kubectl Short Resource Names

Use these to type less:

| Short    | Full Name                |
| -------- | ------------------------ |
| `po`     | pods                     |
| `deploy` | deployments              |
| `svc`    | services                 |
| `ns`     | namespaces               |
| `no`     | nodes                    |
| `ds`     | daemonsets               |
| `sts`    | statefulsets             |
| `rs`     | replicasets              |
| `cm`     | configmaps               |
| `sa`     | serviceaccounts          |
| `pv`     | persistentvolumes        |
| `pvc`    | persistentvolumeclaims   |
| `sc`     | storageclasses           |
| `ing`    | ingresses                |
| `netpol` | networkpolicies          |
| `ep`     | endpoints                |
| `cj`     | cronjobs                 |
| `hpa`    | horizontalpodautoscalers |

### Bash Shortcuts

| Shortcut  | Action                            |
| --------- | --------------------------------- |
| `Ctrl+R`  | Reverse search command history    |
| `Ctrl+A`  | Jump to beginning of line         |
| `Ctrl+E`  | Jump to end of line               |
| `Ctrl+U`  | Delete from cursor to beginning   |
| `Ctrl+K`  | Delete from cursor to end         |
| `Ctrl+W`  | Delete previous word              |
| `Ctrl+C`  | Cancel current command            |
| `Ctrl+L`  | Clear screen                      |
| `!!`      | Repeat last command               |
| `!$`      | Last argument of previous command |
| `Tab`     | Autocomplete (essential!)         |
| `Tab Tab` | Show all completions              |

---

## Vim Survival Guide for Exam

### First Things First — Set Tab to 2 Spaces

```bash
# Run this ONCE at the start of the exam
cat >> ~/.vimrc << 'EOF'
set tabstop=2
set shiftwidth=2
set expandtab
set number
set autoindent
EOF
```

### Essential Vim Commands

| Command         | Action                                    |
| --------------- | ----------------------------------------- |
| `i`             | Enter insert mode                         |
| `Esc`           | Exit insert mode                          |
| `:wq`           | Save and quit                             |
| `:q!`           | Quit without saving                       |
| `dd`            | Delete entire line                        |
| `5dd`           | Delete 5 lines                            |
| `yy`            | Copy (yank) line                          |
| `p`             | Paste below                               |
| `P`             | Paste above                               |
| `u`             | Undo                                      |
| `Ctrl+R`        | Redo                                      |
| `/search`       | Search forward                            |
| `n` / `N`       | Next/previous search result               |
| `:%s/old/new/g` | Find and replace all                      |
| `G`             | Go to end of file                         |
| `gg`            | Go to start of file                       |
| `:set paste`    | Enable paste mode (preserves indentation) |
| `:set nopaste`  | Disable paste mode                        |
| `Shift+V`       | Select entire line (visual mode)          |
| `>` / `<`       | Indent / unindent selected lines          |
| `.`             | Repeat last command                       |

> [!TIP]
> **YAML Indentation Tip:** If you paste YAML and the indentation is wrong, use `:set paste` before pasting, then `:set nopaste` after. Or select lines with `Shift+V`, then indent with `>` or unindent with `<`.

---

## Documentation Navigation

### Allowed Documentation Pages

You can access these during the exam:

- `https://kubernetes.io/docs/` — Main documentation
- `https://kubernetes.io/blog/` — Blog posts
- `https://github.com/kubernetes/` — GitHub repo

### How to Search Efficiently

1. Open the **one allowed extra tab** to `kubernetes.io/docs`
2. Use the **search bar** at the top — it's fast
3. Go directly to the **Tasks** section for step-by-step guides
4. Use the **API Reference** for exact field names

### Most Useful Documentation Pages

| Topic                    | Direct URL                                                                                      |
| ------------------------ | ----------------------------------------------------------------------------------------------- |
| **kubectl Cheat Sheet**  | `kubernetes.io/docs/reference/kubectl/cheatsheet/`                                              |
| **Pod Spec**             | `kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/`                        |
| **Network Policies**     | `kubernetes.io/docs/concepts/services-networking/network-policies/`                             |
| **RBAC**                 | `kubernetes.io/docs/reference/access-authn-authz/rbac/`                                         |
| **Persistent Volumes**   | `kubernetes.io/docs/concepts/storage/persistent-volumes/`                                       |
| **Taints & Tolerations** | `kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/`                         |
| **Probes**               | `kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/` |
| **etcd Backup**          | `kubernetes.io/docs/tasks/administer-cluster/configure-upgrade-etcd/`                           |
| **kubeadm Upgrade**      | `kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/`                          |
| **Ingress**              | `kubernetes.io/docs/concepts/services-networking/ingress/`                                      |

> [!TIP]
> **Pro tip:** Use `kubectl explain` in the terminal whenever possible — it's much faster than switching to the browser tab. Reserve the browser for complex topics like Network Policies or etcd restore procedures.

---

## Common Mistakes to Avoid

### ❌ Fatal Mistakes

| Mistake                             | Impact                          | How to Avoid                                  |
| ----------------------------------- | ------------------------------- | --------------------------------------------- |
| **Wrong context/cluster**           | Zero points for that question   | Always run `kubectl config use-context` first |
| **Wrong namespace**                 | Resource created in wrong place | Use `-n <namespace>` explicitly               |
| **Typos in resource names**         | Resource not found              | Copy-paste from the question                  |
| **Forgetting to save YAML**         | Lost work                       | Always `:wq` in vim                           |
| **Spending 20 min on one question** | Not enough time for others      | Flag and move after 7-8 min                   |

### ⚠️ Common Pitfalls

| Pitfall                              | Solution                                               |
| ------------------------------------ | ------------------------------------------------------ |
| YAML indentation wrong               | Use `set tabstop=2 shiftwidth=2 expandtab` in vim      |
| `kubectl create` vs `kubectl run`    | `run` = Pod, `create deployment` = Deployment          |
| Service selector doesn't match       | Use `kubectl expose` (auto-copies labels)              |
| Static pod name includes node suffix | `pod-name-<node>` — remember this for services         |
| `kubectl edit` changes lost          | apiVersion wrong or validation error — check events    |
| Node in NotReady state               | SSH to node, check kubelet: `systemctl status kubelet` |
| etcd snapshot requires certs         | Always use `--cacert`, `--cert`, `--key` flags         |
| Pod stuck in Pending                 | Check events: scheduler, resource limits, taints       |
| Pod stuck in CrashLoopBackOff        | Check logs: `kubectl logs <pod> --previous`            |

---

## Study Plan & Resources

### Recommended Study Timeline

| Week         | Focus Area           | Activities                                           |
| ------------ | -------------------- | ---------------------------------------------------- |
| **Week 1-2** | Core Concepts        | Pods, Deployments, Services, ConfigMaps, Secrets     |
| **Week 3**   | Scheduling & Storage | Taints, Tolerations, Affinity, PV/PVC, StorageClass  |
| **Week 4**   | Networking           | Services, Ingress, NetworkPolicies, DNS, Gateway API |
| **Week 5**   | Cluster Admin        | RBAC, kubeadm, etcd backup/restore, upgrades         |
| **Week 6**   | Troubleshooting      | Kubelet, DNS, networking, application failures       |
| **Week 7**   | Operators & Tools    | CRDs, Helm, Kustomize, HPA                           |
| **Week 8**   | Mock Exams           | Killer.sh sessions, practice under timed conditions  |

### Recommended Resources

| Resource                           | Type          | Notes                                                         |
| ---------------------------------- | ------------- | ------------------------------------------------------------- |
| **Killer.sh**                      | Mock Exams    | 2 free sessions with CKA purchase — **harder than real exam** |
| **KodeKloud CKA Course**           | Video + Labs  | Best hands-on labs                                            |
| **Mumshad's Udemy CKA**            | Video Course  | Most popular course                                           |
| **kubernetes.io/docs**             | Official Docs | Must-know for exam                                            |
| **CKA Study Companion (Acing...)** | Book/PDF      | Deep-dive reference                                           |
| **killercoda.com**                 | Free Labs     | Free Kubernetes playgrounds                                   |

### Practice Approach

1. **Do NOT just watch videos** — practice every concept hands-on
2. **Set up a local cluster** using `kind`, `minikube`, or `kubeadm`
3. **Practice timed** — solve questions under 2-hour time pressure
4. **Take Killer.sh twice** — once for learning, once for validation
5. **If you score 70%+ on Killer.sh, you'll likely pass the real exam** (Killer.sh is harder)

---

## Readiness Self-Assessment

### Can You Do These Without Docs? (You Should)

Rate yourself: ✅ Confident | ⚠️ Need Practice | ❌ Can't Do

| #   | Task                                                               | Self-Rating |
| --- | ------------------------------------------------------------------ | ----------- |
| 1   | Create a Pod with labels, env vars, and resource limits            |             |
| 2   | Create a Deployment with 3 replicas and perform a rolling update   |             |
| 3   | Expose a Deployment as a NodePort Service                          |             |
| 4   | Create ConfigMap from literals and mount into a Pod                |             |
| 5   | Create a Secret and expose as environment variables                |             |
| 6   | Create a Role and RoleBinding for a ServiceAccount                 |             |
| 7   | Create a NetworkPolicy that only allows ingress from specific Pods |             |
| 8   | Create a PV, PVC, and mount into a Pod                             |             |
| 9   | Schedule a Pod only on specific nodes (nodeSelector + tolerations) |             |
| 10  | Perform etcd snapshot backup                                       |             |
| 11  | Upgrade a cluster using kubeadm                                    |             |
| 12  | Troubleshoot a NotReady node (fix kubelet)                         |             |
| 13  | Create an Ingress with path-based routing                          |             |
| 14  | Debug a CrashLoopBackOff Pod                                       |             |
| 15  | Use `kubectl sort-by` and JSONPath                                 |             |
| 16  | Create a CronJob that runs every 5 minutes                         |             |
| 17  | Create an HPA for a Deployment                                     |             |
| 18  | Use Kustomize to deploy resources                                  |             |
| 19  | Work with CRDs and Operators                                       |             |
| 20  | Switch between contexts and namespaces rapidly                     |             |

### Readiness Checklist

- [ ] Scored **70%+ on Killer.sh** mock exams
- [ ] Can solve most questions **without looking at docs**
- [ ] Comfortable with **vim YAML editing** (indentation, paste mode)
- [ ] Can **switch contexts and namespaces** without thinking
- [ ] Know kubectl **short names** by heart (po, deploy, svc, ns, cm...)
- [ ] Can create Pod, Deployment, Service **imperatively in under 30 seconds**
- [ ] Know the **etcd backup command** from memory
- [ ] Can troubleshoot **kubelet and node issues** systematically
- [ ] Familiar with **RBAC** (Role, RoleBinding, ClusterRole, ClusterRoleBinding)
- [ ] Understand **PV/PVC lifecycle** and reclaim policies
- [ ] Can write **NetworkPolicies** from scratch

> [!TIP]
> **The Rule of Three:** If you can't solve a problem type 3 times in a row without help, practice it more. If you can solve it 3 times in a row from memory, move on to the next topic.

---

> **Final Advice:** The CKA exam is hard but fair. If you've done hands-on practice and can handle Killer.sh mock exams, you're ready. Trust your preparation, manage your time, and don't panic. You've got this! 🚀
