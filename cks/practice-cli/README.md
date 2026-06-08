# CKS Practice CLI

Interactive, exam-style CKS practice with automated lab setup and verification — mirrors the [`cka/practice-cli`](../../cka/practice-cli/) harness. **18 security-focused questions** in official CKS curriculum order (v1.34).

## Requirements

- **Bash 4+**
- A running Kubernetes cluster you control. **A 2-node `kubeadm` cluster is strongly recommended** — many CKS tasks need real node access (AppArmor, seccomp, kube-bench, apiserver flags, encryption-at-rest, Falco, audit logging, RuntimeClass). See [`../study-plan/02-resources.md`](../study-plan/02-resources.md#practice-cluster). killercoda/kind covers ~40% (NetworkPolicy, RBAC, PSA, admission policies, Trivy, immutable containers).
- `kubectl` in PATH and a working kube-context.
- Some questions expect tools on the node: `kube-bench`, `trivy`, `kubesec`, `falco`, `apparmor_parser`. Setup scripts degrade gracefully where a tool is missing; the question/solution still teaches the workflow.

## Usage

```bash
cd cks/practice-cli
./cks
```

Then:
- `[1]` list all questions (grouped by domain),
- `[2]` pick a question → per-question actions:
  - `[S]` **Setup** the scenario (starts a timer — target **≤ 8 min/task**),
  - `[Q]` show the **question**,
  - `[H]` show the **solution** (hint),
  - `[V]` **verify** your solution (PASS/FAIL checks),
  - `[C]` **cleanup**, `[B]` back.

## Layout

```
practice-cli/
├── cks                       # entrypoint
├── cks-exam-qa-guide.md      # question + concept + solution + key points (drives [Q]/[H])
├── lib/
│   ├── colors.sh             # colors, icons, print helpers
│   ├── questions.sh          # the 18-question registry (ID|Title|Domain|Short|Difficulty|Folder)
│   ├── menu.sh               # menus
│   └── setup_map.sh          # setup-path resolution
└── questions/
    └── qNN-<slug>/
        ├── setup.sh          # builds the scenario (idempotent, silent)
        ├── verify.sh         # PASS/FAIL checks, exits non-zero on any FAIL
        └── cleanup.sh        # tears down with --ignore-not-found
```

## Question set (official curriculum order)

| # | Domain | Question |
|---|--------|----------|
| Q1 | Cluster Setup | NetworkPolicy: default-deny + selective allow |
| Q2 | Cluster Setup | CIS Benchmark remediation with kube-bench |
| Q3 | Cluster Setup | Ingress TLS termination |
| Q4 | Cluster Hardening | RBAC least-privilege role + binding |
| Q5 | Cluster Hardening | ServiceAccount token hardening |
| Q6 | Cluster Hardening | Restrict the API server (apiserver flags) |
| Q7 | System Hardening | AppArmor profile on a pod |
| Q8 | System Hardening | Seccomp RuntimeDefault + custom profile |
| Q9 | Microservice Vulns | Enforce Pod Security Admission (restricted) |
| Q10 | Microservice Vulns | Encrypt Secrets at rest (EncryptionConfiguration) |
| Q11 | Microservice Vulns | Admission policy with Kyverno/Gatekeeper |
| Q12 | Microservice Vulns | Runtime sandbox with RuntimeClass (gVisor) |
| Q13 | Supply Chain | Scan images with Trivy and remediate |
| Q14 | Supply Chain | Restrict images via ImagePolicyWebhook/registry |
| Q15 | Supply Chain | Static analysis & manifest hardening (kubesec) |
| Q16 | Runtime Security | Detect threats with Falco rules |
| Q17 | Runtime Security | API server audit logging policy |
| Q18 | Runtime Security | Immutable containers (readOnlyRootFilesystem) |

> ⚠️ **Practice only.** These scenarios edit cluster/node config (apiserver manifest, audit policy, encryption, AppArmor/seccomp). Run them on a disposable practice cluster, **never production**. Always `[C]` cleanup when done.
